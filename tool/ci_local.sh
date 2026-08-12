#!/usr/bin/env bash
# =============================================================================
# Enterprise-standard local CI/CD runner (Linux + macOS)
# =============================================================================
# Mirrors (and extends) GitHub Actions CI so you can validate anytime offline.
#
# Usage:
#   ./tool/ci_local.sh                 # standard gate (recommended before PR)
#   ./tool/ci_local.sh --profile quick # format + analyze + unit tests
#   ./tool/ci_local.sh --profile full  # + goldens + builds + optional integration
#   ./tool/ci_local.sh --profile release
#   ./tool/ci_local.sh --help
#
# Environment overrides:
#   MIN_COVERAGE=40 ./tool/ci_local.sh
#   SKIP_BUILD=1 ./tool/ci_local.sh --profile full
#   CI_STRICT=1 ./tool/ci_local.sh     # treat analyze infos as fatal
# =============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------
PROFILE="standard"
MIN_COVERAGE="${MIN_COVERAGE:-35}"
CI_STRICT="${CI_STRICT:-0}"
SKIP_BUILD="${SKIP_BUILD:-0}"
SKIP_INTEGRATION="${SKIP_INTEGRATION:-0}"
SKIP_GOLDEN="${SKIP_GOLDEN:-0}"
GENERATE_HTML_COVERAGE="${GENERATE_HTML_COVERAGE:-1}"
CONTINUE_ON_ERROR="${CONTINUE_ON_ERROR:-0}"
ARTIFACT_DIR="${ARTIFACT_DIR:-.ci-artifacts}"
REPORT_FILE="${REPORT_FILE:-$ARTIFACT_DIR/ci-report.md}"

OS_NAME="$(uname -s)"
case "$OS_NAME" in
  Darwin*) OS_FAMILY="macos" ;;
  Linux*)  OS_FAMILY="linux" ;;
  *)       OS_FAMILY="unknown" ;;
esac

# Colors (disabled when not a TTY)
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_GREEN=$'\033[32m'
  C_RED=$'\033[31m'
  C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'
  C_BLUE=$'\033[34m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_GREEN=""; C_RED=""; C_YELLOW=""; C_CYAN=""; C_BLUE=""
fi

declare -a STAGE_NAMES=()
declare -a STAGE_STATUS=()
declare -a STAGE_SECONDS=()
FAILURES=0
STARTED_AT="$(date +%s)"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Enterprise local CI/CD runner for Driver Schedule (Linux + macOS)

USAGE
  ./tool/ci_local.sh [options]

PROFILES
  quick     doctor, deps, format, analyze, unit/widget (no coverage gate HTML)
  standard  + coverage gate + golden tests + secret scan   [default]
  full      + platform builds + integration (if device) + outdated report
  release   full + release APK/AAB (and iOS no-codesign on macOS)

OPTIONS
  --profile <name>     quick | standard | full | release
  --min-coverage <n>   Line coverage threshold (default: 35)
  --strict             Fail on analyzer infos (CI_STRICT=1)
  --skip-build         Skip compile/build stages
  --skip-integration   Skip integration_test stage
  --skip-golden        Skip golden tests
  --continue           Do not fail-fast; run all stages and report
  --no-html-coverage   Skip genhtml coverage report
  -h, --help           Show this help

EXAMPLES
  ./tool/ci_local.sh
  ./tool/ci_local.sh --profile full
  CI_STRICT=1 MIN_COVERAGE=50 ./tool/ci_local.sh --profile standard
  ./tool/ci_local.sh --profile release --skip-integration
EOF
}

log()  { printf '%s%s%s\n' "${C_DIM}" "$*" "${C_RESET}"; }
info() { printf '%s▸%s %s\n' "${C_CYAN}" "${C_RESET}" "$*"; }
ok()   { printf '%s✓%s %s\n' "${C_GREEN}" "${C_RESET}" "$*"; }
warn() { printf '%s!%s %s\n' "${C_YELLOW}" "${C_RESET}" "$*"; }
err()  { printf '%s✗%s %s\n' "${C_RED}" "${C_RESET}" "$*"; }

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Required command not found: $1"
    return 1
  fi
}

seconds_now() {
  date +%s
}

run_stage() {
  local name="$1"
  shift
  local start end elapsed status=0

  printf '\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "${C_BLUE}" "${C_RESET}"
  printf '%sSTAGE%s  %s%s%s\n' "${C_BOLD}" "${C_RESET}" "${C_CYAN}" "$name" "${C_RESET}"
  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "${C_BLUE}" "${C_RESET}"

  start="$(seconds_now)"
  set +e
  "$@"
  status=$?
  set -e
  end="$(seconds_now)"
  elapsed=$((end - start))

  STAGE_NAMES+=("$name")
  STAGE_SECONDS+=("$elapsed")

  if [[ $status -eq 0 ]]; then
    STAGE_STATUS+=("PASS")
    ok "$name (${elapsed}s)"
  else
    STAGE_STATUS+=("FAIL")
    FAILURES=$((FAILURES + 1))
    err "$name failed (${elapsed}s)"
    if [[ "$CONTINUE_ON_ERROR" != "1" ]]; then
      write_report
      print_summary
      exit $status
    fi
  fi
  return 0
}

# -----------------------------------------------------------------------------
# Stages
# -----------------------------------------------------------------------------
stage_environment() {
  info "OS family: $OS_FAMILY ($OS_NAME)"
  need_cmd flutter
  need_cmd dart
  need_cmd bash
  need_cmd awk

  mkdir -p "$ARTIFACT_DIR"
  flutter --version | tee "$ARTIFACT_DIR/flutter-version.txt"
  dart --version | tee "$ARTIFACT_DIR/dart-version.txt"
}

stage_doctor() {
  # Non-fatal tooling diagnostics; useful enterprise visibility.
  set +e
  flutter doctor -v | tee "$ARTIFACT_DIR/flutter-doctor.txt"
  local status=$?
  set -e
  if [[ $status -ne 0 ]]; then
    warn "flutter doctor reported issues (continuing)"
  fi
  return 0
}

stage_dependencies() {
  flutter pub get
  # Soft dependency health signal (does not fail the gate).
  set +e
  flutter pub outdated | tee "$ARTIFACT_DIR/pub-outdated.txt"
  set -e
  return 0
}

stage_format() {
  dart format --output=none --set-exit-if-changed lib test integration_test tool
}

stage_analyze() {
  if [[ "$CI_STRICT" == "1" ]]; then
    info "Strict mode: analyzer infos are fatal"
    flutter analyze
  else
    flutter analyze --no-fatal-infos
  fi
}

stage_unit_coverage() {
  if ! command -v lcov >/dev/null 2>&1; then
    warn "lcov not found — installing tip: brew install lcov  (macOS)  |  sudo apt-get install -y lcov  (Linux)"
    err "lcov is required for enterprise coverage gate"
    return 1
  fi

  MIN_COVERAGE="$MIN_COVERAGE" bash tool/check_coverage.sh

  if [[ "$GENERATE_HTML_COVERAGE" == "1" ]] && command -v genhtml >/dev/null 2>&1; then
    genhtml coverage/lcov.info -o "$ARTIFACT_DIR/coverage-html" >/dev/null
    info "HTML coverage: $ARTIFACT_DIR/coverage-html/index.html"
  fi

  cp -f coverage/lcov.info "$ARTIFACT_DIR/lcov.info" 2>/dev/null || true
}

stage_golden() {
  if [[ "$SKIP_GOLDEN" == "1" ]]; then
    warn "Skipping golden tests"
    return 0
  fi
  flutter test test/goldens
}

stage_secret_scan() {
  # Lightweight enterprise secret hygiene — fail if common secret files are tracked.
  local bad=0
  local patterns=(
    'key\.properties$'
    '\.jks$'
    '\.keystore$'
    '\.p12$'
    '\.mobileprovision$'
    'google-services\.json$'
    'GoogleService-Info\.plist$'
    'firebase_options\.dart$'
  )

  # Only fail if tracked files look like real secrets outside known placeholders.
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    for pattern in "${patterns[@]}"; do
      if [[ "$file" =~ $pattern ]]; then
        # Allow committed placeholders / examples.
        if [[ "$file" == *".example"* ]] || [[ "$file" == *"demo"* ]] || [[ "$file" == *"placeholder"* ]]; then
          continue
        fi
        # google-services.json and firebase_options.dart are placeholders in this repo — warn only if they look real.
        if [[ "$file" == "android/app/google-services.json" ]] || [[ "$file" == "lib/core/firebase/firebase_options.dart" ]]; then
          if grep -Eq 'AIzaSyDemo|driver-schedule-demo|Replace-Me' "$file" 2>/dev/null; then
            continue
          fi
        fi
        err "Possible secret tracked in git: $file"
        bad=1
      fi
    done
  done < <(git ls-files)

  # Scan working tree for hard-coded private keys.
  if git grep -nE 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY' -- '*.dart' '*.kt' '*.swift' '*.xml' '*.json' '*.plist' '*.env' >/dev/null 2>&1; then
    err "Private key material detected in repository files"
    bad=1
  fi

  return $bad
}

stage_integration() {
  if [[ "$SKIP_INTEGRATION" == "1" ]]; then
    warn "Skipping integration tests"
    return 0
  fi

  local devices
  devices="$(flutter devices 2>/dev/null || true)"
  if ! echo "$devices" | grep -Eqi 'emulator|ios simulator|android|iphone|ipad|macos|chrome'; then
    warn "No suitable device/emulator found — skipping integration_test"
    info "Start an emulator/simulator, then re-run with --profile full"
    return 0
  fi

  info "Running integration tests on available device"
  flutter test integration_test
}

stage_build_android_debug() {
  if [[ "$SKIP_BUILD" == "1" ]]; then
    warn "Skipping Android debug build"
    return 0
  fi
  flutter build apk --debug
  mkdir -p "$ARTIFACT_DIR/apk"
  cp -f build/app/outputs/flutter-apk/app-debug.apk "$ARTIFACT_DIR/apk/" 2>/dev/null || true
}

stage_build_android_release() {
  if [[ "$SKIP_BUILD" == "1" ]]; then
    warn "Skipping Android release build"
    return 0
  fi
  flutter build apk --release
  flutter build appbundle --release
  mkdir -p "$ARTIFACT_DIR/apk" "$ARTIFACT_DIR/aab"
  cp -f build/app/outputs/flutter-apk/app-release.apk "$ARTIFACT_DIR/apk/" 2>/dev/null || true
  cp -f build/app/outputs/bundle/release/app-release.aab "$ARTIFACT_DIR/aab/" 2>/dev/null || true
}

stage_build_ios() {
  if [[ "$SKIP_BUILD" == "1" ]]; then
    warn "Skipping iOS build"
    return 0
  fi
  if [[ "$OS_FAMILY" != "macos" ]]; then
    warn "iOS build skipped (requires macOS)"
    return 0
  fi
  flutter build ios --no-codesign --debug
}

stage_build_web() {
  if [[ "$SKIP_BUILD" == "1" ]]; then
    warn "Skipping web build"
    return 0
  fi
  # Soft stage: only if web/ exists
  if [[ ! -d web ]]; then
    warn "No web/ directory — skipping web build"
    return 0
  fi
  flutter build web --release
}

stage_sbom_soft() {
  # Soft enterprise inclusion: dependency inventory for compliance reviews.
  flutter pub deps --no-dev --style=compact | tee "$ARTIFACT_DIR/deps-compact.txt" >/dev/null
  flutter pub deps --json > "$ARTIFACT_DIR/deps.json" 2>/dev/null || true
  ok "Dependency inventory written to $ARTIFACT_DIR/deps*"
}

# -----------------------------------------------------------------------------
# Report
# -----------------------------------------------------------------------------
write_report() {
  local end_at total
  end_at="$(seconds_now)"
  total=$((end_at - STARTED_AT))

  {
    echo "# Local CI Report"
    echo
    echo "- **Profile:** \`$PROFILE\`"
    echo "- **OS:** \`$OS_FAMILY\` (\`$OS_NAME\`)"
    echo "- **Started:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "- **Duration:** ${total}s"
    echo "- **Min coverage:** ${MIN_COVERAGE}%"
    echo "- **Strict analyze:** \`$CI_STRICT\`"
    echo
    echo "| Stage | Status | Duration |"
    echo "|-------|--------|----------|"
    local i
    for i in "${!STAGE_NAMES[@]}"; do
      echo "| ${STAGE_NAMES[$i]} | ${STAGE_STATUS[$i]} | ${STAGE_SECONDS[$i]}s |"
    done
    echo
    if [[ $FAILURES -eq 0 ]]; then
      echo "**Result: PASS**"
    else
      echo "**Result: FAIL** ($FAILURES stage(s))"
    fi
  } > "$REPORT_FILE"
}

print_summary() {
  local end_at total i
  end_at="$(seconds_now)"
  total=$((end_at - STARTED_AT))

  printf '\n%s════════════════════════════════════════════════════════════%s\n' "${C_BOLD}" "${C_RESET}"
  printf '%s LOCAL CI SUMMARY%s  profile=%s  os=%s  %ss\n' "${C_BOLD}" "${C_RESET}" "$PROFILE" "$OS_FAMILY" "$total"
  printf '%s════════════════════════════════════════════════════════════%s\n' "${C_BOLD}" "${C_RESET}"

  for i in "${!STAGE_NAMES[@]}"; do
    if [[ "${STAGE_STATUS[$i]}" == "PASS" ]]; then
      printf '  %sPASS%s  %-28s %ss\n' "${C_GREEN}" "${C_RESET}" "${STAGE_NAMES[$i]}" "${STAGE_SECONDS[$i]}"
    else
      printf '  %sFAIL%s  %-28s %ss\n' "${C_RED}" "${C_RESET}" "${STAGE_NAMES[$i]}" "${STAGE_SECONDS[$i]}"
    fi
  done

  echo
  info "Report: $REPORT_FILE"
  info "Artifacts: $ARTIFACT_DIR/"

  if [[ $FAILURES -eq 0 ]]; then
    ok "All stages passed — safe to push / open PR"
  else
    err "$FAILURES stage(s) failed"
  fi
}

# -----------------------------------------------------------------------------
# Args
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --min-coverage)
      MIN_COVERAGE="${2:-}"
      shift 2
      ;;
    --strict)
      CI_STRICT=1
      shift
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --skip-integration)
      SKIP_INTEGRATION=1
      shift
      ;;
    --skip-golden)
      SKIP_GOLDEN=1
      shift
      ;;
    --continue)
      CONTINUE_ON_ERROR=1
      shift
      ;;
    --no-html-coverage)
      GENERATE_HTML_COVERAGE=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

case "$PROFILE" in
  quick|standard|full|release) ;;
  *)
    err "Unknown profile: $PROFILE"
    usage
    exit 2
    ;;
esac

# -----------------------------------------------------------------------------
# Pipeline
# -----------------------------------------------------------------------------
printf '%s\n' "${C_BOLD}Driver Schedule — Enterprise Local CI/CD${C_RESET}"
info "profile=$PROFILE  os=$OS_FAMILY  min_coverage=${MIN_COVERAGE}%  strict=$CI_STRICT"

run_stage "environment" stage_environment
run_stage "flutter-doctor" stage_doctor
run_stage "dependencies" stage_dependencies
run_stage "format" stage_format
run_stage "analyze" stage_analyze

# quick: unit without full coverage HTML requirements still uses coverage script
run_stage "unit-widget-coverage" stage_unit_coverage

if [[ "$PROFILE" != "quick" ]]; then
  run_stage "golden" stage_golden
  run_stage "secret-scan" stage_secret_scan
  run_stage "sbom" stage_sbom_soft
fi

if [[ "$PROFILE" == "full" || "$PROFILE" == "release" ]]; then
  run_stage "integration" stage_integration
  run_stage "build-android-debug" stage_build_android_debug
  run_stage "build-web" stage_build_web
  run_stage "build-ios" stage_build_ios
fi

if [[ "$PROFILE" == "release" ]]; then
  run_stage "build-android-release" stage_build_android_release
fi

write_report
print_summary

if [[ $FAILURES -gt 0 ]]; then
  exit 1
fi
exit 0
