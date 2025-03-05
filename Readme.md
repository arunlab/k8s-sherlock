# K8s-Sherlock: Kubernetes Debugging Toolkit

A comprehensive debugging and troubleshooting toolkit for Kubernetes environments, packaged in a single container based on Debian slim.

## Included Tools

- **Kubernetes Tools**: kubectl, helm, kustomize, kubectx/kubens, stern, krew
- **Cluster Exploration**: k9s, kubectl-neat, dive
- **Security**: trivy, kubeconform
- **Development**: telepresence
- **Networking**: iproute2, iputils-ping, netcat, tcpdump, dnsutils, socat
- **JSON/YAML Processing**: jq, yq
- **Utilities**: curl, wget, git, vim, fzf, and more

## Usage

### Run as a container in your cluster

```bash
kubectl run sherlock --rm -it --image=ghcr.io/arunsanna/k8s-sherlock --restart=Never -- bash
```

---

CI/CD Pipeline
--------

The project includes GitHub Actions workflows for:
* Automated builds on pushes to main branch and tags
* Container image publishing to GitHub Container Registry
* Security scanning with Trivy to detect vulnerabilities
* Layer caching for faster builds

Features
--------

* **Networking Tools**: Comes with `iproute2`, `iputils-ping`, `netcat`, `dnsutils`, `tcpdump`, and `socat`
* **HTTP Tools**: `curl` and `wget` pre-installed for HTTP requests
* **Kubernetes Development**: Full suite of K8s tools including kubectl plugins via krew
* **Interactive Tools**: Terminal-based UIs like k9s and fzf for better productivity

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
docker run -it --rm ghcr.io/arunsanna/k8s-sherlock
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
