#!/usr/bin/env bash
# MLEnv Test Runner
# Version: 2.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MLEnv v2.0.0 Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Run unit tests
echo "▶ Running Unit Tests..."
echo ""
for test in tests/unit/test-*.sh; do
    if [[ -f "$test" ]]; then
        ((TOTAL_SUITES++))
        if bash "$test"; then
            ((PASSED_SUITES++))
        else
            ((FAILED_SUITES++))
        fi
    fi
done

# Run integration tests
echo ""
echo "▶ Running Integration Tests..."
echo ""
for test in tests/integration/test-*.sh; do
    if [[ -f "$test" ]]; then
        ((TOTAL_SUITES++))
        if bash "$test"; then
            ((PASSED_SUITES++))
        else
            ((FAILED_SUITES++))
            echo "  (Some integration tests may fail without running containers)"
        fi
    fi
done

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Suite Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total Test Suites: $TOTAL_SUITES"
echo "Passed: $PASSED_SUITES"
echo "Failed: $FAILED_SUITES"
echo ""

if [[ $FAILED_SUITES -eq 0 ]]; then
    echo "✓ All tests passed!"
    echo ""
    exit 0
else
    echo "⚠ Some tests failed"
    echo ""
    exit 1
fi
