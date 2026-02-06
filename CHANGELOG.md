# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-02-05

### Added

- Debian bookworm-slim based container with comprehensive K8s debugging toolkit
- Kubernetes tools: kubectl, helm, kustomize, kubectx/kubens, stern, krew
- Cluster exploration: k9s, kubectl-neat, dive
- Security scanning: trivy, kubeconform
- Development: telepresence
- Networking: iproute2, iputils-ping, netcat, tcpdump, dnsutils, socat
- JSON/YAML processing: jq, yq
- Utilities: curl, wget, git, vim, fzf, python3
- GitHub Actions CI/CD pipeline with Docker Hub publishing
- Trivy vulnerability scanning in CI
- Pod manifest for Kubernetes deployment (`pod/sherlock.yml`)
- SECURITY.md with vulnerability reporting process
- CONTRIBUTING.MD with contribution guidelines
- Devcontainer configuration for VS Code
- RBAC manifests (ServiceAccount, Role, RoleBinding) in pod manifest
- Multi-arch Docker builds (linux/amd64 and linux/arm64)
- Non-root user (`sherlock`, UID 999) for improved container security
- Security hardening: `seccompProfile: RuntimeDefault`, `readOnlyRootFilesystem`, dropped capabilities
- Dockerfile layer optimization for smaller image size
- CI pipeline fails on CRITICAL/HIGH vulnerabilities (build gate)

### Fixed

- Documentation: corrected license references from MIT to MPL 2.0
- Documentation: corrected image references from ghcr.io to Docker Hub
- Documentation: corrected org references from VivSoftOrg to arunlab
