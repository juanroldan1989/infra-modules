#!/bin/bash
# Static Analysis Test Suite for ECS Cluster Module
# This script runs comprehensive static analysis checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Change to module directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODULE_DIR="${SCRIPT_DIR}/.."
cd "${MODULE_DIR}"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}ECS Cluster Module - Static Analysis${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2

    echo -e "${YELLOW}Running: ${test_name}${NC}"

    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED: ${test_name}${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo ""
        return 0
    else
        echo -e "${RED}✗ FAILED: ${test_name}${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo ""
        return 1
    fi
}

# 1. Check required tools
echo -e "${BLUE}Checking prerequisites...${NC}"
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}terraform is required but not installed.${NC}" >&2; exit 1; }
command -v tflint >/dev/null 2>&1 || { echo -e "${YELLOW}Warning: tflint not installed. Install with: brew install tflint${NC}"; }
command -v tfsec >/dev/null 2>&1 || { echo -e "${YELLOW}Warning: tfsec not installed. Install with: brew install tfsec${NC}"; }
command -v checkov >/dev/null 2>&1 || { echo -e "${YELLOW}Warning: checkov not installed. Install with: pip install checkov${NC}"; }
echo ""

# 2. Terraform Format Check
run_test "Terraform Format Check" "terraform fmt -check -recursive"

# 3. Terraform Initialization
run_test "Terraform Init" "terraform init -backend=false"

# 4. Terraform Validation
run_test "Terraform Validate" "terraform validate"

# 5. TFLint
if command -v tflint >/dev/null 2>&1; then
    echo -e "${YELLOW}Initializing TFLint...${NC}"
    tflint --init
    run_test "TFLint Analysis" "tflint --recursive"
else
    echo -e "${YELLOW}Skipping TFLint (not installed)${NC}"
    echo ""
fi

# 6. TFSec Security Scan
if command -v tfsec >/dev/null 2>&1; then
    run_test "TFSec Security Scan" "tfsec . --format=default --no-color"
else
    echo -e "${YELLOW}Skipping TFSec (not installed)${NC}"
    echo ""
fi

# 7. Checkov Policy Scan
if command -v checkov >/dev/null 2>&1; then
    run_test "Checkov Policy Scan" "checkov -d . --compact --quiet --framework terraform"
else
    echo -e "${YELLOW}Skipping Checkov (not installed)${NC}"
    echo ""
fi

# 8. Check for TODOs and FIXMEs
run_test "Check for TODOs/FIXMEs" "! grep -r 'TODO\|FIXME' *.tf 2>/dev/null"

# 9. Check for hardcoded values that should be variables
run_test "Check for Hardcoded Secrets" "! grep -rE '(password|secret|key)\s*=\s*\"[^$]' *.tf 2>/dev/null"

# 10. Verify all variables have descriptions
run_test "All Variables Have Descriptions" "test -f variables.tf && ! grep -A 3 'variable' variables.tf | grep -B 3 'description' | grep -v 'description' | grep 'variable' | wc -l | grep -q '^0$' || true"

# 11. Verify all outputs have descriptions
run_test "All Outputs Have Descriptions" "test -f outputs.tf && ! grep -A 3 'output' outputs.tf | grep -B 3 'description' | grep -v 'description' | grep 'output' | wc -l | grep -q '^0$' || true"

# Print summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All static analysis tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix the issues above.${NC}"
    exit 1
fi
