# SimpleHot Backend

A microservice-based backend system with Express Gateway, Authentication Service, and User Service.

## Architecture

The system is comprised of the following components:

1. **API Gateway** - Entry point for all client requests, handles routing to microservices
2. **Authentication Service** - Handles user registration, login, and token verification
3. **User Service** - Manages user profiles and social graph functionality
4. **PostgreSQL Database** - Persistent storage for user data and authentication information

## Setup

### Prerequisites

- Node.js (v14 or later)
- npm (v6 or later)
- Docker and Docker Compose (optional, for containerized setup)
- PostgreSQL (if running in local mode)

### Installation

1. Clone this repository:

```bash
git clone <repository-url>
cd simplehot-backend
```

2. Run the setup script:

```bash
./setup.sh
```

The setup script will:
- Check for Docker availability
- Ask if you want to run in Docker or local mode
- Install all necessary dependencies
- Configure environment variables
- Check for and configure .npmrc file for npm authentication
- Start the services based on your chosen mode

## Development Modes

### Docker Mode

The Docker mode runs all services in containers, including PostgreSQL. This provides an isolated environment that's easier to set up and consistent across different development machines.

To start in Docker mode:

```bash
docker-compose up
```

### Local Mode

In local mode, you'll need to run each service individually and have PostgreSQL installed locally.

To start in local mode:

```bash
# Start the gateway
cd gateway && npm start

# Start the auth service
cd auth-service && npm start

# Start the user service
cd user-service && npm start
```

## Troubleshooting

### npm Authentication Issues in Docker

If you encounter npm authentication errors during Docker builds, it could be due to:

1. Missing .npmrc file in your home directory
2. Using HTTP instead of HTTPS in your npm registry URLs

The setup script will help you fix these issues by:
- Creating a basic .npmrc file if one doesn't exist
- Offering to update HTTP URLs to HTTPS
- Mounting your .npmrc file from your host machine to the Docker containers

This approach allows Docker containers to use your local npm authentication without having to store credentials in the Docker images.

### Development with VS Code Dev Containers

This project includes configurations for VS Code Dev Containers. To use them:

1. Install the "Remote - Containers" extension in VS Code
2. Open the project folder in VS Code
3. Click the green button in the bottom-left corner and select "Reopen in Container"

This will start the development environment in a container with all necessary tools and extensions pre-configured.

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

#### Health Check
- `GET /health` - Check if the gateway is running

## Services Overview

| Service | Port | Purpose | Status |
|---------|------|---------|--------|
| **API Gateway** | 5050 | Request routing & aggregation | ✅ |
| **User Service** | 5002 | User management & social features | ✅ |
| **PostgreSQL** | 5432 | Database | ✅ |
| **pgAdmin** | 8080 | Database administration | ✅ |

## Quick Start Commands

```bash
# Start all services
docker-compose up

# Run comprehensive tests  
./test-endpoints.sh

# View database
open http://localhost:8080

# Check service health
curl http://localhost:5050/health

# View logs
docker-compose logs -f gateway
docker-compose logs -f user-service
```

## License

MIT 