# K8s-Sherlock: Kubernetes Debugging Toolkit

[![CI](https://github.com/arunlab/k8s-sherlock/actions/workflows/build-and-publish.yml/badge.svg)](https://github.com/arunlab/k8s-sherlock/actions/workflows/build-and-publish.yml)
[![Docker Hub](https://img.shields.io/docker/pulls/arunsanna/k8s-sherlock)](https://hub.docker.com/r/arunsanna/k8s-sherlock)
[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)

A comprehensive debugging and troubleshooting toolkit for Kubernetes environments, packaged in a single container based on Debian slim.

## Included Tools

| Category                | Tools                                                    |
| ----------------------- | -------------------------------------------------------- |
| **Kubernetes**          | kubectl, helm, kustomize, kubectx/kubens, stern, krew    |
| **Cluster Exploration** | k9s, kubectl-neat, dive                                  |
| **Security**            | trivy, kubeconform                                       |
| **Development**         | telepresence                                             |
| **Networking**          | iproute2, iputils-ping, netcat, tcpdump, dnsutils, socat |
| **JSON/YAML**           | jq, yq                                                   |
| **Utilities**           | curl, wget, git, vim, fzf, python3                       |

> **Note:** Tools are installed at their latest versions at image build time. Rebuild the image to pick up newer releases.

## Quick Start

### Prerequisites

- A Kubernetes cluster up and running
- kubectl installed and configured

### Run as a one-off container in your cluster

```bash
kubectl run sherlock --rm -it --image=arunsanna/k8s-sherlock --restart=Never -- bash
```

### Deploy as a persistent pod

First, set up the namespace and RBAC (see `pod/sherlock.yml` for the full manifest including ServiceAccount and Role bindings):

```bash
kubectl apply -f pod/sherlock.yml --namespace=<namespace_name>
```

Then exec into it:

```bash
kubectl exec -it sherlock --namespace=<namespace_name> -- /bin/bash
```

### Run standalone with Docker

```bash
docker run -it --rm arunsanna/k8s-sherlock
```

## Architecture

The image is built on `debian:bookworm-slim` and supports `linux/amd64` and `linux/arm64`.

## CI/CD Pipeline

The project uses a GitHub Actions workflow that:

- Builds on pushes to `main` and version tags (`v*`)
- Scans the image with Trivy for CRITICAL/HIGH vulnerabilities
- Publishes to [Docker Hub](https://hub.docker.com/r/arunsanna/k8s-sherlock) (not on PRs)
- Uses layer caching for faster builds

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting instructions and security practices.

## Contributing

Contributions are welcome! Please read the [Contributing Guidelines](CONTRIBUTING.MD) for details.

## Troubleshooting

| Problem                                        | Solution                                                                                                               |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Pod has no permissions to list/get resources   | Apply the RBAC manifests in `pod/sherlock.yml` (ServiceAccount, Role, RoleBinding)                                     |
| Tools not found inside the container           | Verify `$PATH` includes `/usr/local/bin` — run `echo $PATH` inside the pod                                             |
| Pod stuck in `CrashLoopBackOff`                | Check logs with `kubectl logs sherlock` — the pod requires `command: ["sleep", "infinity"]` or similar to stay running |
| `kubectl` inside pod returns connection errors | Ensure the ServiceAccount token is mounted and the API server is reachable from the pod network                        |

## Uninstall

Remove the sherlock pod and associated RBAC resources:

```bash
kubectl delete -f pod/sherlock.yml --namespace=<namespace_name>
```

To also remove a one-off run:

```bash
kubectl delete pod sherlock
```

## License

This project is licensed under the Mozilla Public License 2.0. See the [LICENSE](LICENSE) file for details.
