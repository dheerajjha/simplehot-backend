#!/bin/bash

echo "🚀 Testing SimpleHot Backend Stock Endpoints"
echo "==========================================="

BASE_URL="http://localhost:5050"
FAILED_TESTS=0
TOTAL_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to run test and check response
run_test() {
    local test_name="$1"
    local expected_status="$2"
    local response="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Extract status code if curl was used with -w flag
    if [[ $response == *"HTTP_STATUS:"* ]]; then
        status_code=$(echo "$response" | grep -o 'HTTP_STATUS:[0-9]*' | cut -d':' -f2)
        response_body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    else
        status_code="unknown"
        response_body="$response"
    fi
    
    echo -e "${BLUE}$test_name${NC}"
    echo "Expected Status: $expected_status, Got: $status_code"
    echo "Response: $response_body"
    
    if [[ "$status_code" == "$expected_status" ]] || [[ "$expected_status" == "any" ]]; then
        echo -e "${GREEN}✅ PASSED${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# First register a test user to get authentication token
TIMESTAMP=$(date +%s)
TEST_EMAIL="stocktester${TIMESTAMP}@example.com"
TEST_PASSWORD="password123"

echo "🧪 Setting up test user for authentication..."
echo "Test Email: $TEST_EMAIL"
echo ""

# Register a new user
REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

# Extract token
TOKEN=$(echo $REGISTER_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')
echo "Auth Token: $TOKEN"
echo ""

echo -e "${YELLOW}📊 STOCK API TESTS${NC}"
echo "===================="

# Test 1: Get trending stocks
echo "📝 Test 1: Get trending stocks"
TRENDING_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/stocks/trending \
  -H "Authorization: Bearer $TOKEN")
run_test "Get trending stocks" "200" "$TRENDING_RESPONSE"

# Test 2: Get stock details
echo "📝 Test 2: Get stock details"
STOCK_DETAILS_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/stocks/RELIANCE \
  -H "Authorization: Bearer $TOKEN")
run_test "Get stock details" "200" "$STOCK_DETAILS_RESPONSE"

# Test 3: Search stocks
echo "📝 Test 3: Search stocks"
SEARCH_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/api/stocks/search/REL" \
  -H "Authorization: Bearer $TOKEN")
run_test "Search stocks" "200" "$SEARCH_RESPONSE"

# Test 4: Get stock history
echo "📝 Test 4: Get stock history"
HISTORY_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/api/stocks/RELIANCE/history?period=week" \
  -H "Authorization: Bearer $TOKEN")
run_test "Get stock history" "200" "$HISTORY_RESPONSE"

# Test 5: Try to get stock details without auth token
echo "📝 Test 5: Get stock details without auth token"
NO_AUTH_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/stocks/RELIANCE)
run_test "Get stock details without auth token" "401" "$NO_AUTH_RESPONSE"

# Summary
echo -e "${YELLOW}📊 TEST SUMMARY${NC}"
echo "==============="
echo "Total Tests: $TOTAL_TESTS"
echo "Failed Tests: $FAILED_TESTS"
echo "Passed Tests: $((TOTAL_TESTS - FAILED_TESTS))"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED_TESTS TESTS FAILED${NC}"
    exit 1
fi 