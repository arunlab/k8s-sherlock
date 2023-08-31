#!/bin/bash

set -e

# Build the Docker image
echo "Building Docker image..."
docker build -t test-image .

# Run the container
echo "Running Docker container..."
container_id=$(docker run -d --rm test-image sleep 600)

# Helper function to run commands inside the container
run_command() {
  docker exec $container_id "$@"
}

# Check installed packages
echo "Checking installed packages..."

run_command ip || (echo "Error: ip not installed" && exit 1)
run_command ping -c 1 8.8.8.8 || (echo "Error: ping not installed" && exit 1)
run_command traceroute -n -m 1 8.8.4.4 || (echo "Error: traceroute not installed" && exit 1)
run_command nc --help || (echo "Error: netcat not installed" && exit 1)
run_command dig google.com || (echo "Error: dnsutils not installed" && exit 1)
run_command telnet --version || (echo "Error: telnet not installed" && exit 1)
run_command curl --version || (echo "Error: curl not installed" && exit 1)
run_command wget --version || (echo "Error: wget not installed" && exit 1)
run_command docker --version || (echo "Error: docker-ce-cli not installed" && exit 1)
run_command python3 --version || (echo "Error: python3 not installed" && exit 1)
run_command pip3 --version || (echo "Error: pip3 not installed" && exit 1)
run_command aws --version || (echo "Error: awscli not installed" && exit 1)

# All tests passed
echo "All tests passed successfully."

# Cleanup
docker stop $container_id
docker rmi test-image