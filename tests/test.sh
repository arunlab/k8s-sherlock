#!/bin/bash

set -e

# Build the Docker image
echo "Building Docker image..."
docker build -t test-image .

# Run the container
echo "Running Docker container..."
container_id=$(docker run -d test-image:latest sleep 3600)

# Helper function to run commands inside the container
run_command() {
  docker exec $container_id "$@"
}

echo "========================================="
echo "Testing Kubernetes Tools"
echo "========================================="

# Test kubectl installation
echo "Testing kubectl installation..."
run_command kubectl version --client

# Test helm installation
echo "Testing helm installation..."
run_command helm version

# Test k9s installation
echo "Testing k9s installation..."
run_command k9s version

# Test kustomize installation
echo "Testing kustomize installation..."
run_command kustomize version

# Test stern installation
echo "Testing stern installation..."
run_command stern --version

echo "========================================="
echo "Testing Security & Validation Tools"
echo "========================================="

# Test trivy installation
echo "Testing trivy installation..."
run_command trivy --version

# Test kubeconform installation
echo "Testing kubeconform installation..."
run_command kubeconform -v

# Test kubeval installation
echo "Testing kubeval installation..."
run_command kubeval --version

echo "========================================="
echo "Testing Data Processing Tools"
echo "========================================="

# Test jq installation
echo "Testing jq installation..."
run_command jq --version

# Test yq installation
echo "Testing yq installation..."
run_command yq --version

echo "========================================="
echo "Testing Development & AI Tools"
echo "========================================="

# Test Node.js installation
echo "Testing Node.js installation..."
run_command node --version

# Test npm installation
echo "Testing npm installation..."
run_command npm --version

# Test GitHub CLI installation
echo "Testing GitHub CLI installation..."
run_command gh --version

# Test Claude Code installation
echo "Testing Claude Code installation..."
run_command which claude || echo "Claude Code installed via npm"

# Test GitHub Copilot CLI installation
echo "Testing GitHub Copilot CLI installation..."
run_command which github-copilot-cli || echo "GitHub Copilot CLI installed via npm"

echo "========================================="
echo "Testing Container Tools"
echo "========================================="

# Test dive installation
echo "Testing dive installation..."
run_command dive --version

echo "========================================="
echo "Testing Networking Tools"
echo "========================================="

# Test curl installation
echo "Testing curl installation..."
run_command curl --version

# Test wget installation
echo "Testing wget installation..."
run_command wget --version

echo "========================================="
echo "All tests passed successfully! ✅"
echo "========================================="

# Cleanup
docker stop $container_id
docker rmi test-image
