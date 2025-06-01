# Testing Guide for SimpleHot Backend

## Overview

This document provides comprehensive information about testing the SimpleHot Backend API and visualizing the PostgreSQL database.

## Test Coverage

The `test-endpoints.sh` script provides **exhaustive coverage** of all API endpoints with 39 comprehensive tests covering:

### 🔐 Authentication Tests (10 tests)
- ✅ Valid user registration (with proper email and password validation)
- ❌ Duplicate user registration (should fail)
- ❌ Invalid email format (should fail) - **Enhanced with regex validation**
- ❌ Weak password (should fail) - **Enhanced with strength requirements**
- ✅ Valid login (with email validation)
- ❌ Invalid credentials (should fail)
- ❌ Non-existent user login (should fail)
- ✅ Valid token verification
- ❌ Invalid token verification (should fail)
- ❌ Missing token verification (should fail)

### 👤 User Management Tests (10 tests)
- ✅ Get authenticated user profile
- ❌ Get unauthenticated user profile (should fail)
- ✅ Update user profile with valid data
- ❌ Update user profile without authentication (should fail)
- ✅ Get user by ID
- ✅ Follow another user
- ✅ Handle duplicate follow requests gracefully
- ✅ Get user followers
- ✅ Get users being followed
- ✅ Unfollow a user

### 📄 Posts Tests (13 tests)
- ✅ Create valid post
- ❌ Create post without authentication (should fail)
- ❌ Create post with empty content (should fail)
- ✅ Get post by ID
- ❌ Get non-existent post (should fail)
- ✅ Get posts by user ID
- ✅ Like a post
- ✅ Handle duplicate likes gracefully
- ✅ Get post likes
- ✅ Unlike a post
- ✅ Add comment to post
- ❌ Add empty comment (should fail)
- ✅ Get post comments

### 🔍 Security & Edge Cases (5 tests)
- ❌ Malformed JSON handling
- ❌ Missing Content-Type header
- ❌ SQL injection attempts - **Enhanced with email validation**
- ✅ XSS content handling
- ✅ Very long content handling

### 🏥 Health Check (1 test)
- ✅ API Gateway health status

## Recent Improvements

### ✅ **HTTP Status Code Compliance**
- Updated test expectations for creation endpoints to expect `201 Created` instead of `200 OK`
- This follows proper REST API standards where resource creation should return 201

### ✅ **Enhanced Input Validation**
- **Email Validation**: Added regex validation for proper email format (`/^[^\s@]+@[^\s@]+\.[^\s@]+$/`)
- **Password Strength**: Enforced minimum 8 characters with at least one letter and one number
- **Security**: Email validation now catches malformed emails before authentication attempts

### ✅ **Validation Rules**
```javascript
// Email validation
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// Password validation  
const isValidPassword = (password) => {
  // Password must be at least 8 characters long and contain at least one letter and one number
  const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$/;
  return passwordRegex.test(password);
};
```

## Running Tests

### Prerequisites
Make sure your backend services are running:

```bash
# Using Docker (recommended)
docker-compose up

# Or manually start services
cd gateway && npm start &
cd user-service && npm start &
```

### Execute Test Suite

```bash
# Make the script executable
chmod +x test-endpoints.sh

# Run all tests
./test-endpoints.sh
```

### Test Output

The script provides:
- 🎨 **Color-coded output** (Green ✅ = Pass, Red ❌ = Fail)
- 📊 **HTTP status code validation**
- 📈 **Test summary with pass/fail counts**
- 🔍 **Detailed response inspection**
- 🚨 **Exit codes** (0 = all passed, 1 = some failed)

### Example Output
```
🚀 Testing SimpleHot Backend API Endpoints - COMPREHENSIVE COVERAGE
==================================================================

🔐 AUTHENTICATION TESTS
========================

📝 Test 1: Register new user (valid)
Expected Status: 201, Got: 201
Response: {"token":"eyJ...","user":{"id":1,"email":"testuser1234@example.com"}}
✅ PASSED

📝 Test 3: Register with invalid email
Expected Status: 400, Got: 400
Response: {"message":"Please provide a valid email address"}
✅ PASSED

📝 Test 4: Register with weak password
Expected Status: 400, Got: 400
Response: {"message":"Password must be at least 8 characters long and contain at least one letter and one number"}
✅ PASSED

📊 TEST SUMMARY
===============
Total Tests: 39
Failed Tests: 0
Passed Tests: 39
🎉 ALL TESTS PASSED!
```

## Database Visualization with pgAdmin

### What is pgAdmin?

pgAdmin is the most popular and feature-rich Open Source administration and development platform for PostgreSQL. It's the equivalent of phpMyAdmin for PostgreSQL databases.

### Features
- 🌐 **Web-based interface** - Access from any browser
- 📊 **Visual query builder** - Create queries without SQL knowledge
- 🔍 **Database explorer** - Browse tables, views, functions
- 📈 **Performance monitoring** - Query analysis and optimization
- 🛠️ **Schema management** - Create, modify, and drop database objects
- 📋 **Data editing** - Insert, update, delete records visually
- 📤 **Import/Export** - CSV, JSON, SQL formats
- 🔐 **User management** - Manage database users and permissions

### Accessing pgAdmin

1. **Start the services:**
   ```bash
   docker-compose up
   ```

2. **Open pgAdmin in your browser:**
   ```
   http://localhost:8080
   ```

3. **Login credentials:**
   - **Email:** `admin@simplehot.com`
   - **Password:** `admin123`

### Connecting to PostgreSQL Database

1. **Add New Server:**
   - Right-click "Servers" → "Create" → "Server..."

2. **General Tab:**
   - **Name:** `SimpleHot Database`

3. **Connection Tab:**
   - **Host:** `postgres` (Docker service name)
   - **Port:** `5432`
   - **Database:** `user_db`
   - **Username:** `postgres`
   - **Password:** `postgres`

4. **Click "Save"**

### Database Structure

Once connected, you'll see:

```
SimpleHot Database/
├── Databases/
│   └── user_db/
│       ├── Schemas/
│       │   └── public/
│       │       ├── Tables/
│       │       │   ├── users
│       │       │   ├── posts
│       │       │   ├── likes
│       │       │   ├── comments
│       │       │   ├── follows
│       │       │   └── _prisma_migrations
│       │       ├── Views/
│       │       ├── Functions/
│       │       └── Sequences/
```

### Common Tasks in pgAdmin

#### View Table Data
1. Navigate to `Tables` → `users`
2. Right-click → "View/Edit Data" → "All Rows"

#### Run Custom Queries
1. Click "Query Tool" (SQL icon)
2. Write your SQL:
   ```sql
   SELECT u.email, COUNT(p.id) as post_count 
   FROM users u 
   LEFT JOIN posts p ON u.id = p.user_id 
   GROUP BY u.id, u.email;
   ```
3. Click "Execute" (▶️)

#### Export Data
1. Right-click table → "Import/Export Data..."
2. Choose format (CSV, JSON, etc.)
3. Configure options and export

#### Monitor Performance
1. Go to "Dashboard" tab
2. View real-time statistics
3. Analyze slow queries

### Alternative Database Tools

If you prefer other tools:

#### 1. **Adminer** (Lightweight alternative)
Add to docker-compose.yml:
```yaml
adminer:
  image: adminer:latest
  ports:
    - "8081:8080"
  networks:
    - microservices-network
```
Access: `http://localhost:8081`

#### 2. **DBeaver** (Desktop application)
- Download from: https://dbeaver.io/
- Connection: `localhost:5432`, database: `user_db`

#### 3. **psql** (Command line)
```bash
# Connect directly to PostgreSQL container
docker exec -it simplehot-backend_postgres_1 psql -U postgres -d user_db

# Or from host (if PostgreSQL client installed)
psql -h localhost -p 5432 -U postgres -d user_db
```

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: API Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Start services
      run: docker-compose up -d
      
    - name: Wait for services
      run: sleep 30
      
    - name: Run tests
      run: ./test-endpoints.sh
      
    - name: Stop services
      run: docker-compose down
```

## Test Data Management

### Reset Test Data
```bash
# Reset database
docker-compose down -v
docker-compose up

# Or manually clean tables
docker exec -it simplehot-backend_postgres_1 psql -U postgres -d user_db -c "
TRUNCATE users, posts, likes, comments, follows RESTART IDENTITY CASCADE;
"
```

### Seed Test Data
Create `seed-data.sql`:
```sql
INSERT INTO users (email, password, name, username) VALUES 
('john@example.com', '$2b$10$...', 'John Doe', 'johndoe'),
('jane@example.com', '$2b$10$...', 'Jane Smith', 'janesmith');

INSERT INTO posts (user_id, content) VALUES 
(1, 'Hello world!'),
(2, 'My first post!');
```

## Troubleshooting

### Common Issues

1. **Tests failing with connection errors:**
   ```bash
   # Check if services are running
   docker-compose ps
   
   # Check logs
   docker-compose logs gateway
   docker-compose logs user-service
   ```

2. **pgAdmin connection issues:**
   - Ensure PostgreSQL container is running
   - Use container name `postgres` as host
   - Check network connectivity

3. **Permission denied on test script:**
   ```bash
   chmod +x test-endpoints.sh
   ```

### Debug Mode

Run tests with verbose output:
```bash
# Add debug flag to curl commands
curl -v -s -w "HTTP_STATUS:%{http_code}" ...
```

## Best Practices

1. **Run tests before deployment**
2. **Monitor test execution time**
3. **Keep test data isolated**
4. **Document test scenarios**
5. **Regular database backups**
6. **Security testing with invalid inputs**
7. **Performance testing with load**

## Contributing

When adding new endpoints:

1. **Add corresponding tests** to `test-endpoints.sh`
2. **Update this documentation**
3. **Test both success and failure cases**
4. **Verify database changes in pgAdmin**
5. **Check security implications**

---

**Happy Testing! 🚀** 