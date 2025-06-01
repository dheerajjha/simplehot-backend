# SimpleHot Backend

A microservice-based backend system for SimpleHot, a Twitter-like platform for Indian stock predictions.

## Architecture

The system is comprised of the following components:

1. **API Gateway** - Entry point for all client requests, handles routing to microservices
2. **Auth Service** - Handles user registration, login, and token verification
3. **User Service** - Manages user profiles and social graph functionality
4. **Post Service** - Handles general posts functionality
5. **Stock Service** - Provides stock data and search functionality
6. **Prediction Service** - Manages stock predictions and verification
7. **Redis** - Caching for frequently accessed data
8. **PostgreSQL Database** - Persistent storage for all services

## Setup

### Prerequisites

- Node.js (v14 or later)
- npm (v6 or later)
- Docker and Docker Compose (for containerized setup)
- PostgreSQL (if running in local mode)

### Installation

1. Clone this repository:

```bash
git clone <repository-url>
cd simplehot-backend
```

2. Start services using Docker:

```bash
docker-compose up
```

## Development Modes

### Docker Mode

The Docker mode runs all services in containers, including PostgreSQL and Redis. This provides an isolated environment that's easier to set up and consistent across different development machines.

To start in Docker mode:

```bash
docker-compose up
```

To start a specific service:

```bash
docker-compose up gateway auth-service
```

### Local Mode

In local mode, you'll need to run each service individually and have PostgreSQL and Redis installed locally.

To start in local mode:

```bash
# Start the gateway
cd gateway && npm start

# Start the auth service
cd auth-service && npm start

# Start other services similarly
```

## API Documentation

### Gateway API (Port 5050)

The Gateway provides a unified API for all microservices:

#### Authentication Endpoints
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Authenticate a user and get a token
- `GET /api/auth/verify` - Verify a JWT token

#### User Management Endpoints
- `GET /api/users/profile` - Get the current user's profile (authenticated)
- `GET /api/users/:id` - Get a user's profile by ID (authenticated)
- `PUT /api/users/profile` - Update the current user's profile (authenticated)
- `GET /api/users/:id/followers` - Get a user's followers (authenticated)
- `GET /api/users/:id/following` - Get users that a user is following (authenticated)
- `POST /api/users/:id/follow` - Follow a user (authenticated)
- `DELETE /api/users/:id/follow` - Unfollow a user (authenticated)

#### Posts Endpoints
- `POST /api/posts` - Create a new post (authenticated)
- `GET /api/posts/:id` - Get a post by ID (authenticated)
- `GET /api/posts/user/:userId` - Get all posts by a user (authenticated)
- `POST /api/posts/:id/like` - Like a post (authenticated)
- `DELETE /api/posts/:id/like` - Unlike a post (authenticated)
- `GET /api/posts/:id/likes` - Get all likes for a post (authenticated)
- `POST /api/posts/:id/comments` - Add a comment to a post (authenticated)
- `GET /api/posts/:id/comments` - Get all comments for a post (authenticated)

#### Stock Endpoints
- `GET /api/stocks/trending` - Get trending stocks
- `GET /api/stocks/:symbol` - Get stock details
- `GET /api/stocks/search` - Search for stocks
- `GET /api/stocks/:symbol/history` - Get stock historical data

#### Prediction Endpoints
- `POST /api/predictions` - Create a stock prediction
- `GET /api/predictions/trending` - Get trending predictions
- `GET /api/predictions/stock/:symbol` - Get predictions for a stock
- `GET /api/predictions/user/:userId` - Get user's predictions
- `POST /api/predictions/:id/like` - Like a prediction
- `DELETE /api/predictions/:id/like` - Unlike a prediction
- `POST /api/predictions/:id/comments` - Comment on a prediction
- `GET /api/predictions/:id/comments` - Get prediction comments

#### Health Check
- `GET /health` - Check if the gateway is running

## Services Overview

| Service | Port | Purpose | Status |
|---------|------|---------|--------|
| **API Gateway** | 5050 | Request routing & aggregation | ✅ |
| **Auth Service** | 5001 | Authentication & authorization | ✅ |
| **User Service** | 5002 | User management & social features | ✅ |
| **Post Service** | 5003 | Post management & interactions | ✅ |
| **Stock Service** | 5004 | Stock data & search | ✅ |
| **Prediction Service** | 5005 | Stock predictions | ✅ |
| **PostgreSQL** | 5432 | Database | ✅ |
| **Redis** | 6379 | Caching | ✅ |
| **pgAdmin** | 8080 | Database administration | ✅ |

## Quick Start Commands

```bash
# Start all services
docker-compose up

# Run comprehensive tests  
./tests/run-all-tests.sh

# Run specific test suite
./tests/auth-tests.sh

# View database
open http://localhost:8080

# Check service health
curl http://localhost:5050/health

# View logs
docker-compose logs -f gateway
docker-compose logs -f auth-service
```

## License

MIT 