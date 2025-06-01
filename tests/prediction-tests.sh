#!/bin/bash

echo "🚀 Testing SimpleHot Backend Prediction Endpoints"
echo "================================================"

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
TEST_EMAIL="predictiontester${TIMESTAMP}@example.com"
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

echo -e "${YELLOW}🔮 PREDICTION API TESTS${NC}"
echo "========================"

# Test 1: Create a stock prediction
echo "📝 Test 1: Create a stock prediction"
CREATE_PREDICTION_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/predictions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "stockSymbol": "RELIANCE",
    "stockName": "Reliance Industries",
    "targetPrice": 2600.00,
    "targetDate": "2024-12-31T00:00:00Z",
    "direction": "up",
    "description": "Expecting growth due to new projects",
    "currentPrice": 2500.75
  }')
run_test "Create a stock prediction" "201" "$CREATE_PREDICTION_RESPONSE"

# Extract prediction ID
PREDICTION_ID=$(echo $CREATE_PREDICTION_RESPONSE | sed 's/HTTP_STATUS:[0-9]*$//' | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Extracted Prediction ID: $PREDICTION_ID"
echo ""

# Test 2: Get trending predictions
echo "📝 Test 2: Get trending predictions"
TRENDING_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/predictions/trending \
  -H "Authorization: Bearer $TOKEN")
run_test "Get trending predictions" "200" "$TRENDING_RESPONSE"

# Test 3: Create prediction without required fields
echo "📝 Test 3: Create prediction without required fields"
INVALID_PREDICTION_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/predictions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "stockSymbol": "RELIANCE"
  }')
run_test "Create prediction without required fields" "400" "$INVALID_PREDICTION_RESPONSE"

# Test 4: Get predictions for a stock
echo "📝 Test 4: Get predictions for a stock"
STOCK_PREDICTIONS_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/predictions/stock/RELIANCE \
  -H "Authorization: Bearer $TOKEN")
run_test "Get predictions for a stock" "200" "$STOCK_PREDICTIONS_RESPONSE"

# Test 5: Get user's predictions
echo "📝 Test 5: Get user's predictions"
USER_ID=$(echo $REGISTER_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)
USER_PREDICTIONS_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/api/predictions/user/$USER_ID" \
  -H "Authorization: Bearer $TOKEN")
run_test "Get user's predictions" "200" "$USER_PREDICTIONS_RESPONSE"

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