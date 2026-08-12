#!/usr/bin/env bash
set -euo pipefail

MIN_COVERAGE="${MIN_COVERAGE:-35}"

flutter test test/presentation test/domain test/data --coverage

if ! command -v lcov >/dev/null 2>&1; then
  echo "lcov is required to enforce coverage thresholds"
  exit 1
fi

SUMMARY=$(lcov --summary coverage/lcov.info 2>&1)
LINE=$(echo "$SUMMARY" | awk '/lines/ {print $2}')
PERCENT=${LINE%\%}

echo "Line coverage: ${PERCENT}% (minimum ${MIN_COVERAGE}%)"

awk -v actual="$PERCENT" -v min="$MIN_COVERAGE" 'BEGIN { exit !(actual + 0 >= min + 0) }' || {
  echo "Coverage ${PERCENT}% is below the required ${MIN_COVERAGE}%"
  exit 1
}

echo "Coverage check passed."
