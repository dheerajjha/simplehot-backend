#!/bin/bash

echo "🚀 Testing SimpleHot Backend API Endpoints"
echo "=========================================="

BASE_URL="http://localhost:5050"

# Generate unique email with timestamp
TIMESTAMP=$(date +%s)
TEST_EMAIL="testuser${TIMESTAMP}@example.com"

# Test 1: Register a new user
echo "📝 Test 1: Register new user"
REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"testpass123\"}")
echo "Response: $REGISTER_RESPONSE"

# Extract token
TOKEN=$(echo $REGISTER_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Token: $TOKEN"
echo ""

# Test 2: Login
echo "🔐 Test 2: Login"
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"testpass123\"}")
echo "Response: $LOGIN_RESPONSE"
echo ""

# Test 3: Verify token
echo "✅ Test 3: Verify token"
VERIFY_RESPONSE=$(curl -s $BASE_URL/api/auth/verify \
  -H "x-auth-token: $TOKEN")
echo "Response: $VERIFY_RESPONSE"
echo ""

# Test 4: Get user profile
echo "👤 Test 4: Get user profile"
PROFILE_RESPONSE=$(curl -s $BASE_URL/api/users/profile \
  -H "x-auth-token: $TOKEN")
echo "Response: $PROFILE_RESPONSE"
echo ""

# Test 5: Update user profile
echo "✏️ Test 5: Update user profile"
UPDATE_RESPONSE=$(curl -s -X PUT $BASE_URL/api/users/profile \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $TOKEN" \
  -d "{\"name\":\"Test User\",\"username\":\"testuser${TIMESTAMP}\",\"bio\":\"I am a test user!\"}")
echo "Response: $UPDATE_RESPONSE"
echo ""

# Test 6: Create a post
echo "📄 Test 6: Create a post"
POST_RESPONSE=$(curl -s -X POST $BASE_URL/api/posts \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $TOKEN" \
  -d '{"content":"Hello world! This is my test post."}')
echo "Response: $POST_RESPONSE"

# Extract post ID
POST_ID=$(echo $POST_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Post ID: $POST_ID"
echo ""

# Test 7: Get the post
echo "📖 Test 7: Get the post"
GET_POST_RESPONSE=$(curl -s --max-time 10 $BASE_URL/api/posts/$POST_ID \
  -H "x-auth-token: $TOKEN")
echo "Response: $GET_POST_RESPONSE"
echo ""

# Test 8: Like the post
echo "❤️ Test 8: Like the post"
LIKE_RESPONSE=$(curl -s --max-time 10 -X POST $BASE_URL/api/posts/$POST_ID/like \
  -H "x-auth-token: $TOKEN")
echo "Response: $LIKE_RESPONSE"
echo ""

# Test 9: Add a comment
echo "💬 Test 9: Add a comment"
COMMENT_RESPONSE=$(curl -s --max-time 10 -X POST $BASE_URL/api/posts/$POST_ID/comments \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $TOKEN" \
  -d '{"content":"Great post!"}')
echo "Response: $COMMENT_RESPONSE"
echo ""

# Test 10: Get comments
echo "📝 Test 10: Get comments"
GET_COMMENTS_RESPONSE=$(curl -s --max-time 10 $BASE_URL/api/posts/$POST_ID/comments \
  -H "x-auth-token: $TOKEN")
echo "Response: $GET_COMMENTS_RESPONSE"
echo ""

# Test 11: Health check
echo "🏥 Test 11: Health check"
HEALTH_RESPONSE=$(curl -s --max-time 10 $BASE_URL/health)
echo "Response: $HEALTH_RESPONSE"
echo ""

echo "✨ All tests completed!"
echo "Check the responses above to verify everything is working correctly." 