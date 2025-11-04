# K8s-Sherlock: Kubernetes Debugging Toolkit

A comprehensive debugging and troubleshooting toolkit for Kubernetes environments, packaged in a single container based on Debian 12 (Bookworm) slim. **Now with Claude Code and GitHub Copilot CLI!**

## Included Tools (40+ tools)

### Kubernetes Tools
- **kubectl** - Kubernetes command-line tool (latest stable)
- **helm** - Kubernetes package manager (v3 latest)
- **kustomize** - Kubernetes configuration customization (latest)
- **kubectx/kubens** - Context and namespace switcher (latest)
- **stern** - Multi-pod log tailing (latest)
- **krew** - kubectl plugin manager (latest)
- **kubectl plugins**: ctx, ns, neat

### Cluster Exploration & Visualization
- **k9s** - Terminal UI for Kubernetes (latest)
- **dive** - Docker/container image explorer (latest)
- **lazydocker** - Docker management TUI (latest)
- **k1s** - Kubernetes cluster visualization

### Security & Validation
- **trivy** - Vulnerability scanner (latest)
- **kubeconform** - Kubernetes manifest validator (latest)
- **kubeval** - Kubernetes YAML validation (latest)

### Development & AI Assistants
- **telepresence** - Local development with K8s (latest)
- **Claude Code** - Anthropic's official Claude CLI (latest)
- **GitHub Copilot CLI** - AI-powered code assistant (latest)
- **GitHub CLI (gh)** - GitHub command-line tool (latest)

### Networking Tools
- **iproute2** - Advanced networking utilities
- **iputils-ping** - Network connectivity testing
- **netcat-openbsd** - Network connections and debugging
- **tcpdump** - Packet capture and analysis
- **dnsutils** - DNS troubleshooting tools
- **socat** - Socket relay and redirector

### Data Processing
- **jq** - JSON processor and query tool
- **yq** - YAML processor (latest)

### Languages & Runtimes
- **Node.js** - LTS version for modern tooling
- **Python 3** - With pip and venv support

### General Utilities
- **curl, wget** - HTTP clients
- **git** - Version control
- **vim** - Text editor
- **fzf** - Fuzzy finder
- **And more...**

## Usage

### Run as a container in your cluster

```bash
kubectl run sherlock --rm -it --image=arunsanna/k8s-sherlock:latest --restart=Never -- bash
```

---

## What's New

### Latest Updates (2025)
- ✅ **Updated base image** to Debian 12 (Bookworm) - latest stable
- ✅ **All tools updated** to their latest versions
- ✅ **Added Claude Code** - Anthropic's official Claude CLI for AI assistance
- ✅ **Added GitHub Copilot CLI** - AI-powered code completion and suggestions
- ✅ **Added GitHub CLI (gh)** - Complete GitHub workflow integration
- ✅ **Added lazydocker** - Terminal UI for Docker management
- ✅ **Added kubeval** - Additional Kubernetes manifest validation
- ✅ **Added Node.js LTS** - For modern JavaScript/TypeScript tooling
- ✅ **Enhanced kubectl aliases** - k, kgp, kgs, kgd, kl, kd for faster workflows
- ✅ **Improved installation methods** - All tools fetch latest versions dynamically

---

CI/CD Pipeline
--------

The project includes GitHub Actions workflows for:
* Automated builds on pushes to main branch and tags
* Container image publishing to Docker Hub (`arunsanna/k8s-sherlock`)
* Security scanning with Trivy to detect CRITICAL and HIGH vulnerabilities
* Layer caching for faster builds and optimized image size

Features
--------

* **AI-Powered Development**: Claude Code and GitHub Copilot CLI for intelligent code assistance
* **Latest Tools**: All tools dynamically fetch latest versions at build time
* **Networking Tools**: Complete networking stack with `iproute2`, `iputils-ping`, `netcat`, `dnsutils`, `tcpdump`, and `socat`
* **HTTP Tools**: `curl` and `wget` pre-installed for HTTP requests
* **Kubernetes Development**: Full suite of K8s tools including kubectl plugins via krew
* **Interactive Tools**: Terminal-based UIs like k9s, lazydocker, and fzf for better productivity
* **Security Scanning**: Built-in Trivy for container and cluster vulnerability scanning
* **Helpful Aliases**: Pre-configured kubectl aliases (k, kgp, kgs, etc.) for faster commands

---

Quick Start
-----------

### Prerequisites

* A Kubernetes cluster up and running
* kubectl installed and configured

### Deploy K8s-Sherlock Pod

```bash
kubectl apply -f pod/sherlock.yml --namespace=<namespace_name>
```

### Run Standalone

You can also pull and run the container directly with Docker:

```bash
docker run -it --rm arunsanna/k8s-sherlock:latest
```

---

Usage
-----

Once the K8s-Sherlock pod is up and running, you can `exec` into it to use the tools.

bash

```bash
kubectl exec -it <pod-name> -- /bin/bash
```

---

Contributing
------------

We love contributions! Please read the [Contributing Guidelines](CONTRIBUTING.MD) for more information on how to get involved.

---

License
-------

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
