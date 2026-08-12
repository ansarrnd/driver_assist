# Enterprise local CI/CD shortcuts (Linux + macOS)
# Requires: Flutter SDK, bash, lcov (for coverage)
#
#   make ci           # standard gate (before every PR)
#   make ci-quick     # fast feedback loop
#   make ci-full      # builds + integration if device available
#   make ci-release   # release artifacts
#   make ci-strict    # infos are fatal

.PHONY: help ci ci-quick ci-full ci-release ci-strict format analyze test goldens coverage doctor clean-ci

help:
	@echo "Driver Schedule — local CI targets"
	@echo ""
	@echo "  make ci           Standard enterprise gate (recommended before PR)"
	@echo "  make ci-quick     Format + analyze + unit/coverage"
	@echo "  make ci-full      Standard + builds + integration (if device)"
	@echo "  make ci-release   Full + release APK/AAB (+ iOS on macOS)"
	@echo "  make ci-strict    Standard with analyzer infos fatal"
	@echo "  make format       dart format lib/test/integration_test/tool"
	@echo "  make analyze      flutter analyze --no-fatal-infos"
	@echo "  make test         unit/widget tests"
	@echo "  make goldens      golden tests"
	@echo "  make coverage     coverage gate (MIN_COVERAGE, default 35)"
	@echo "  make doctor       flutter doctor -v"
	@echo "  make clean-ci     remove .ci-artifacts/"

ci:
	bash tool/ci_local.sh --profile standard

ci-quick:
	bash tool/ci_local.sh --profile quick

ci-full:
	bash tool/ci_local.sh --profile full

ci-release:
	bash tool/ci_local.sh --profile release

ci-strict:
	CI_STRICT=1 bash tool/ci_local.sh --profile standard --strict

format:
	dart format lib test integration_test tool

analyze:
	flutter analyze --no-fatal-infos

test:
	flutter test test/presentation test/domain test/data

goldens:
	flutter test test/goldens

coverage:
	bash tool/check_coverage.sh

doctor:
	flutter doctor -v

clean-ci:
	rm -rf .ci-artifacts coverage/html
