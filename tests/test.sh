#!/bin/bash

set -e

# Build the Docker image
echo "Building Docker image..."
docker build -t test-image .

# Run the container
echo "Running Docker container..."
container_id=$(docker run -d test-image:latest)

# Helper function to run commands inside the container
run_command() {
  docker exec $container_id "$@"
}

# Test kubectl installation
echo "Testing kubectl installation..."
run_command kubectl version --client

# Test helm installation
echo "Testing helm installation..."
run_command helm version

# All tests passed
echo "All tests passed successfully."

# Cleanup
docker stop $container_id
docker rmi test-image
