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

- `POST /auth/register` - Register a new user
- `POST /auth/login` - Authenticate a user and get a token
- `GET /users/profile` - Get the current user's profile (authenticated)
- `GET /users/:id` - Get a user's profile by ID
- `PUT /users/profile` - Update the current user's profile (authenticated)
- `POST /users/follow/:id` - Follow a user (authenticated)
- `DELETE /users/follow/:id` - Unfollow a user (authenticated)
- `GET /users/followers` - Get the current user's followers (authenticated)
- `GET /users/following` - Get the users the current user is following (authenticated)

## License

MIT 