#!/bin/bash

echo "🚀 Testing SimpleHot Backend Authentication Endpoints"
echo "===================================================="

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

# Generate unique identifiers
TIMESTAMP=$(date +%s)
TEST_EMAIL="testuser${TIMESTAMP}@example.com"

echo "🧪 Starting authentication API testing..."
echo "Test Email: $TEST_EMAIL"
echo ""

echo -e "${YELLOW}🔐 AUTHENTICATION TESTS${NC}"
echo "========================"

# Test 1: Register a new user (valid)
echo "📝 Test 1: Register new user (valid)"
REGISTER_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"testpass123\"}")
run_test "Register new user (valid)" "201" "$REGISTER_RESPONSE"

# Extract token
TOKEN=$(echo $REGISTER_RESPONSE | sed 's/HTTP_STATUS:[0-9]*$//' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Extracted Token: $TOKEN"
echo ""

# Test 2: Register duplicate user (should fail)
echo "📝 Test 2: Register duplicate user (should fail)"
DUPLICATE_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"testpass123\"}")
run_test "Register duplicate user" "400" "$DUPLICATE_RESPONSE"

# Test 3: Login with valid credentials
echo "🔐 Test 3: Login with valid credentials"
LOGIN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"testpass123\"}")
run_test "Login with valid credentials" "200" "$LOGIN_RESPONSE"

# Test 4: Login with invalid credentials
echo "🔐 Test 4: Login with invalid credentials"
INVALID_LOGIN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"wrongpassword\"}")
run_test "Login with invalid credentials" "401" "$INVALID_LOGIN_RESPONSE"

# Test 5: Verify valid token
echo "✅ Test 5: Verify valid token"
VERIFY_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/auth/verify \
  -H "x-auth-token: $TOKEN")
run_test "Verify valid token" "200" "$VERIFY_RESPONSE"

# Test 6: Verify invalid token
echo "✅ Test 6: Verify invalid token"
INVALID_TOKEN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/auth/verify \
  -H "x-auth-token: invalid_token_here")
run_test "Verify invalid token" "401" "$INVALID_TOKEN_RESPONSE"

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