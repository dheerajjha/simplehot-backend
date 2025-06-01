#!/bin/bash

echo "🚀 Testing SimpleHot Backend API Endpoints - COMPREHENSIVE COVERAGE"
echo "=================================================================="

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
TEST_EMAIL_2="testuser2${TIMESTAMP}@example.com"

echo "🧪 Starting comprehensive API testing..."
echo "Test Email 1: $TEST_EMAIL"
echo "Test Email 2: $TEST_EMAIL_2"
echo ""

# =============================================================================
# AUTHENTICATION TESTS
# =============================================================================

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

# Test 3: Register with invalid email
echo "📝 Test 3: Register with invalid email"
INVALID_EMAIL_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"invalid-email\",\"password\":\"testpass123\"}")
run_test "Register with invalid email" "400" "$INVALID_EMAIL_RESPONSE"

# Test 4: Register with weak password
echo "📝 Test 4: Register with weak password"
WEAK_PASSWORD_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"weak${TIMESTAMP}@example.com\",\"password\":\"123\"}")
run_test "Register with weak password" "400" "$WEAK_PASSWORD_RESPONSE"

# Test 5: Login with valid credentials
echo "🔐 Test 5: Login with valid credentials"
LOGIN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"testpass123\"}")
run_test "Login with valid credentials" "200" "$LOGIN_RESPONSE"

# Test 6: Login with invalid credentials
echo "🔐 Test 6: Login with invalid credentials"
INVALID_LOGIN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"wrongpassword\"}")
run_test "Login with invalid credentials" "401" "$INVALID_LOGIN_RESPONSE"

# Test 7: Login with non-existent user
echo "🔐 Test 7: Login with non-existent user"
NONEXISTENT_LOGIN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"nonexistent@example.com\",\"password\":\"testpass123\"}")
run_test "Login with non-existent user" "401" "$NONEXISTENT_LOGIN_RESPONSE"

# Test 8: Verify valid token
echo "✅ Test 8: Verify valid token"
VERIFY_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/auth/verify \
  -H "x-auth-token: $TOKEN")
run_test "Verify valid token" "200" "$VERIFY_RESPONSE"

# Test 9: Verify invalid token
echo "✅ Test 9: Verify invalid token"
INVALID_TOKEN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/auth/verify \
  -H "x-auth-token: invalid_token_here")
run_test "Verify invalid token" "401" "$INVALID_TOKEN_RESPONSE"

# Test 10: Verify without token
echo "✅ Test 10: Verify without token"
NO_TOKEN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/auth/verify)
run_test "Verify without token" "401" "$NO_TOKEN_RESPONSE"

# =============================================================================
# USER MANAGEMENT TESTS
# =============================================================================

echo -e "${YELLOW}👤 USER MANAGEMENT TESTS${NC}"
echo "========================="

# Test 11: Get user profile (authenticated)
echo "👤 Test 11: Get user profile (authenticated)"
PROFILE_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/users/profile \
  -H "x-auth-token: $TOKEN")
run_test "Get user profile (authenticated)" "200" "$PROFILE_RESPONSE"

# Extract user ID for later tests
USER_ID=$(echo $PROFILE_RESPONSE | sed 's/HTTP_STATUS:[0-9]*$//' | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Extracted User ID: $USER_ID"
echo ""

# Test 12: Get user profile (unauthenticated)
echo "👤 Test 12: Get user profile (unauthenticated)"
UNAUTH_PROFILE_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/users/profile)
run_test "Get user profile (unauthenticated)" "401" "$UNAUTH_PROFILE_RESPONSE"

# Test 13: Update user profile (valid)
echo "✏️ Test 13: Update user profile (valid)"
UPDATE_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X PUT $BASE_URL/api/users/profile \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $TOKEN" \
  -d "{\"name\":\"Test User\",\"username\":\"testuser${TIMESTAMP}\",\"bio\":\"I am a test user!\"}")
run_test "Update user profile (valid)" "200" "$UPDATE_RESPONSE"

# Test 14: Update user profile (unauthenticated)
echo "✏️ Test 14: Update user profile (unauthenticated)"
UNAUTH_UPDATE_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X PUT $BASE_URL/api/users/profile \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test User\",\"username\":\"testuser${TIMESTAMP}\",\"bio\":\"I am a test user!\"}")
run_test "Update user profile (unauthenticated)" "401" "$UNAUTH_UPDATE_RESPONSE"

# Test 15: Get user by ID (authenticated)
echo "👤 Test 15: Get user by ID (authenticated)"
if [[ -n "$USER_ID" ]]; then
    GET_USER_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/users/$USER_ID \
      -H "x-auth-token: $TOKEN")
    run_test "Get user by ID (authenticated)" "200" "$GET_USER_RESPONSE"
else
    echo "Skipping - no user ID available"
    echo ""
fi

# Create second user for follow/unfollow tests
echo "📝 Creating second user for social features testing..."
REGISTER_2_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL_2\",\"password\":\"testpass123\"}")

TOKEN_2=$(echo $REGISTER_2_RESPONSE | sed 's/HTTP_STATUS:[0-9]*$//' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Get second user's profile to extract ID
PROFILE_2_RESPONSE=$(curl -s $BASE_URL/api/users/profile -H "x-auth-token: $TOKEN_2")
USER_ID_2=$(echo $PROFILE_2_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

echo "Second User ID: $USER_ID_2"
echo ""

# Test 16: Follow a user
echo "👥 Test 16: Follow a user"
if [[ -n "$USER_ID_2" ]]; then
    FOLLOW_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/users/$USER_ID_2/follow \
      -H "x-auth-token: $TOKEN")
    run_test "Follow a user" "201" "$FOLLOW_RESPONSE"
else
    echo "Skipping - no second user ID available"
    echo ""
fi

# Test 17: Follow same user again (should handle gracefully)
echo "👥 Test 17: Follow same user again"
if [[ -n "$USER_ID_2" ]]; then
    FOLLOW_AGAIN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/users/$USER_ID_2/follow \
      -H "x-auth-token: $TOKEN")
    run_test "Follow same user again" "any" "$FOLLOW_AGAIN_RESPONSE"
else
    echo "Skipping - no second user ID available"
    echo ""
fi

# Test 18: Get followers
echo "👥 Test 18: Get followers"
if [[ -n "$USER_ID_2" ]]; then
    FOLLOWERS_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/users/$USER_ID_2/followers \
      -H "x-auth-token: $TOKEN")
    run_test "Get followers" "200" "$FOLLOWERS_RESPONSE"
else
    echo "Skipping - no second user ID available"
    echo ""
fi

# Test 19: Get following
echo "👥 Test 19: Get following"
if [[ -n "$USER_ID" ]]; then
    FOLLOWING_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/users/$USER_ID/following \
      -H "x-auth-token: $TOKEN")
    run_test "Get following" "200" "$FOLLOWING_RESPONSE"
else
    echo "Skipping - no user ID available"
    echo ""
fi

# Test 20: Unfollow a user
echo "👥 Test 20: Unfollow a user"
if [[ -n "$USER_ID_2" ]]; then
    UNFOLLOW_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X DELETE $BASE_URL/api/users/$USER_ID_2/follow \
      -H "x-auth-token: $TOKEN")
    run_test "Unfollow a user" "200" "$UNFOLLOW_RESPONSE"
else
    echo "Skipping - no second user ID available"
    echo ""
fi

# =============================================================================
# POSTS TESTS
# =============================================================================

echo -e "${YELLOW}📄 POSTS TESTS${NC}"
echo "==============="

# Test 21: Create a post (valid)
echo "📄 Test 21: Create a post (valid)"
POST_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $TOKEN" \
  -d '{"content":"Hello world! This is my test post."}')
run_test "Create a post (valid)" "201" "$POST_RESPONSE"

# Extract post ID
POST_ID=$(echo $POST_RESPONSE | sed 's/HTTP_STATUS:[0-9]*$//' | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Extracted Post ID: $POST_ID"
echo ""

# Test 22: Create a post (unauthenticated)
echo "📄 Test 22: Create a post (unauthenticated)"
UNAUTH_POST_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts \
  -H "Content-Type: application/json" \
  -d '{"content":"This should fail"}')
run_test "Create a post (unauthenticated)" "401" "$UNAUTH_POST_RESPONSE"

# Test 23: Create a post (empty content)
echo "📄 Test 23: Create a post (empty content)"
EMPTY_POST_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $TOKEN" \
  -d '{"content":""}')
run_test "Create a post (empty content)" "400" "$EMPTY_POST_RESPONSE"

# Test 24: Get a post by ID
echo "📖 Test 24: Get a post by ID"
if [[ -n "$POST_ID" ]]; then
    GET_POST_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/posts/$POST_ID \
      -H "x-auth-token: $TOKEN")
    run_test "Get a post by ID" "200" "$GET_POST_RESPONSE"
else
    echo "Skipping - no post ID available"
    echo ""
fi

# Test 25: Get non-existent post
echo "📖 Test 25: Get non-existent post"
NONEXISTENT_POST_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/posts/99999 \
  -H "x-auth-token: $TOKEN")
run_test "Get non-existent post" "404" "$NONEXISTENT_POST_RESPONSE"

# Test 26: Get posts by user ID
echo "📖 Test 26: Get posts by user ID"
if [[ -n "$USER_ID" ]]; then
    USER_POSTS_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/posts/user/$USER_ID \
      -H "x-auth-token: $TOKEN")
    run_test "Get posts by user ID" "200" "$USER_POSTS_RESPONSE"
else
    echo "Skipping - no user ID available"
    echo ""
fi

# Test 27: Like a post
echo "❤️ Test 27: Like a post"
if [[ -n "$POST_ID" ]]; then
    LIKE_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts/$POST_ID/like \
      -H "x-auth-token: $TOKEN")
    run_test "Like a post" "201" "$LIKE_RESPONSE"
else
    echo "Skipping - no post ID available"
    echo ""
fi

# Test 28: Like same post again (should handle gracefully)
echo "❤️ Test 28: Like same post again"
if [[ -n "$POST_ID" ]]; then
    LIKE_AGAIN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts/$POST_ID/like \
      -H "x-auth-token: $TOKEN")
    run_test "Like same post again" "any" "$LIKE_AGAIN_RESPONSE"
else
    echo "Skipping - no post ID available"
    echo ""
fi

# Test 29: Get likes for a post
echo "❤️ Test 29: Get likes for a post"
if [[ -n "$POST_ID" ]]; then
    GET_LIKES_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/posts/$POST_ID/likes \
      -H "x-auth-token: $TOKEN")
    run_test "Get likes for a post" "200" "$GET_LIKES_RESPONSE"
else
    echo "Skipping - no post ID available"
    echo ""
fi

# Test 30: Unlike a post
echo "💔 Test 30: Unlike a post"
if [[ -n "$POST_ID" ]]; then
    UNLIKE_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X DELETE $BASE_URL/api/posts/$POST_ID/like \
      -H "x-auth-token: $TOKEN")
    run_test "Unlike a post" "200" "$UNLIKE_RESPONSE"
else
    echo "Skipping - no post ID available"
    echo ""
fi

# Test 31: Add a comment to a post
echo "💬 Test 31: Add a comment to a post"
if [[ -n "$POST_ID" ]]; then
    COMMENT_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts/$POST_ID/comments \
      -H "Content-Type: application/json" \
      -H "x-auth-token: $TOKEN" \
      -d '{"content":"Great post!"}')
    run_test "Add a comment to a post" "201" "$COMMENT_RESPONSE"
else
    echo "Skipping - no post ID available"
    echo ""
fi

# Test 32: Add empty comment (should fail)
echo "💬 Test 32: Add empty comment"
if [[ -n "$POST_ID" ]]; then
    EMPTY_COMMENT_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts/$POST_ID/comments \
      -H "Content-Type: application/json" \
      -H "x-auth-token: $TOKEN" \
      -d '{"content":""}')
    run_test "Add empty comment" "400" "$EMPTY_COMMENT_RESPONSE"
else
    echo "Skipping - no post ID available"
    echo ""
fi

# Test 33: Get comments for a post
echo "📝 Test 33: Get comments for a post"
if [[ -n "$POST_ID" ]]; then
    GET_COMMENTS_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/api/posts/$POST_ID/comments \
      -H "x-auth-token: $TOKEN")
    run_test "Get comments for a post" "200" "$GET_COMMENTS_RESPONSE"
else
    echo "Skipping - no post ID available"
    echo ""
fi

# =============================================================================
# EDGE CASES AND ERROR HANDLING
# =============================================================================

echo -e "${YELLOW}🔍 EDGE CASES AND ERROR HANDLING${NC}"
echo "================================="

# Test 34: Malformed JSON
echo "🔍 Test 34: Malformed JSON"
MALFORMED_JSON_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":}')
run_test "Malformed JSON" "400" "$MALFORMED_JSON_RESPONSE"

# Test 35: Missing Content-Type header
echo "🔍 Test 35: Missing Content-Type header"
MISSING_CONTENT_TYPE_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/register \
  -d '{"email":"test@example.com","password":"testpass123"}')
run_test "Missing Content-Type header" "400" "$MISSING_CONTENT_TYPE_RESPONSE"

# Test 36: SQL Injection attempt
echo "🔍 Test 36: SQL Injection attempt"
SQL_INJECTION_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com; DROP TABLE users; --","password":"password"}')
run_test "SQL Injection attempt" "400" "$SQL_INJECTION_RESPONSE"

# Test 37: XSS attempt in post content
echo "🔍 Test 37: XSS attempt in post content"
XSS_POST_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $TOKEN" \
  -d '{"content":"<script>alert(\"XSS\")</script>"}')
run_test "XSS attempt in post content" "any" "$XSS_POST_RESPONSE"

# Test 38: Very long content
echo "🔍 Test 38: Very long content"
LONG_CONTENT=$(printf 'A%.0s' {1..10000})
LONG_CONTENT_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/posts \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $TOKEN" \
  -d "{\"content\":\"$LONG_CONTENT\"}")
run_test "Very long content" "any" "$LONG_CONTENT_RESPONSE"

# =============================================================================
# HEALTH CHECK
# =============================================================================

echo -e "${YELLOW}🏥 HEALTH CHECK${NC}"
echo "==============="

# Test 39: Health check
echo "🏥 Test 39: Health check"
HEALTH_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" $BASE_URL/health)
run_test "Health check" "200" "$HEALTH_RESPONSE"

# =============================================================================
# SUMMARY
# =============================================================================

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