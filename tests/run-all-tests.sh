#!/bin/bash

echo "🚀 Running All SimpleHot Backend Tests"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TOTAL_FAILED=0

# Run all test scripts and collect results
echo -e "${YELLOW}📋 Running Authentication Tests${NC}"
echo "------------------------------"
./tests/auth-tests.sh
AUTH_EXIT_CODE=$?
if [ $AUTH_EXIT_CODE -ne 0 ]; then
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

echo -e "${YELLOW}📋 Running Stock Tests${NC}"
echo "----------------------"
./tests/stock-tests.sh
STOCK_EXIT_CODE=$?
if [ $STOCK_EXIT_CODE -ne 0 ]; then
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

echo -e "${YELLOW}📋 Running Prediction Tests${NC}"
echo "----------------------------"
./tests/prediction-tests.sh
PREDICTION_EXIT_CODE=$?
if [ $PREDICTION_EXIT_CODE -ne 0 ]; then
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

echo -e "${YELLOW}📋 Running Comprehensive Tests${NC}"
echo "-------------------------------"
./tests/test-endpoints.sh
COMPREHENSIVE_EXIT_CODE=$?
if [ $COMPREHENSIVE_EXIT_CODE -ne 0 ]; then
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

# Print overall summary
echo -e "${YELLOW}📊 OVERALL TEST SUMMARY${NC}"
echo "======================="
echo "Authentication Tests: $([ $AUTH_EXIT_CODE -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo "Stock Tests: $([ $STOCK_EXIT_CODE -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo "Prediction Tests: $([ $PREDICTION_EXIT_CODE -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo "Comprehensive Tests: $([ $COMPREHENSIVE_EXIT_CODE -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo ""

if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TEST SUITES PASSED!${NC}"
    exit 0
else
    echo -e "${RED}❌ $TOTAL_FAILED TEST SUITE(S) FAILED${NC}"
    exit 1
fi 