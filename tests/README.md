# SimpleHot Backend Tests

This directory contains various test scripts for testing the SimpleHot backend services.

## Test Script Structure

The test suite is organized as follows:

- `auth-tests.sh` - Tests for authentication endpoints
- `stock-tests.sh` - Tests for stock data endpoints
- `prediction-tests.sh` - Tests for prediction endpoints
- `test-endpoints.sh` - Comprehensive test suite for all endpoints
- `run-all-tests.sh` - Master script that runs all test suites
- `docker-tests.sh` - Script to run tests in a Docker environment

## Running Tests

### Running Individual Test Suites

You can run individual test suites like this:

```bash
# From project root directory
./tests/auth-tests.sh
./tests/stock-tests.sh
./tests/prediction-tests.sh
./tests/test-endpoints.sh
```

### Running All Tests

To run all test suites at once:

```bash
./tests/run-all-tests.sh
```

### Running Tests in Docker Environment

The `docker-tests.sh` script automates the process of:
1. Building and starting all services using Docker Compose
2. Waiting for services to be ready
3. Running all tests
4. Displaying logs if tests fail
5. Cleaning up (stopping all containers)

Run the Docker tests like this:

```bash
./tests/docker-tests.sh
```

## Test Output

Each test script will output:
- Test name and description
- Expected and actual HTTP status codes
- Response bodies
- Test summary with pass/fail status

## Creating New Tests

To create new test scripts:

1. Create a new `.sh` file in the tests directory
2. Copy the basic structure from one of the existing test scripts
3. Add your test cases with appropriate curl commands
4. Make the script executable: `chmod +x tests/your-new-test.sh`
5. Update `run-all-tests.sh` to include your new test script

## Troubleshooting

If tests are failing, check the following:

1. Make sure all services are running and healthy
   ```bash
   curl http://localhost:5050/health
   ```

2. Check service logs for errors
   ```bash
   docker-compose logs gateway
   docker-compose logs auth-service
   docker-compose logs stock-service
   # etc.
   ```

3. Verify that your test data is valid (correct formats, required fields, etc.)

4. If running in Docker, make sure ports are correctly mapped and not blocked by a firewall