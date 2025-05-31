# SimpleHot Backend

## Service Endpoints

- **Gateway API**: http://localhost:5050
- **Auth Service**: http://localhost:5001
- **User Service**: http://localhost:5002

## API Integration Guide

### Authentication

#### Login
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "token": "your_jwt_token"
}
```

#### Register
```
POST /api/auth/register
Content-Type: application/json

{
  "email": "new@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "token": "your_jwt_token"
}
```

### User Operations

For all user endpoints, include the auth token in the header:
```
x-auth-token: your_jwt_token
```

#### Get User Profile
```
GET /api/users/profile
```

#### Update User Profile
```
PUT /api/users/profile
Content-Type: application/json

{
  "name": "Updated Name"
}
```

## Testing Credentials

- Email: user@example.com
- Password: password123 