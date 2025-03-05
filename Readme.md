# K8s-Sherlock: Kubernetes Debugging Toolkit

A comprehensive debugging and troubleshooting toolkit for Kubernetes environments, packaged in a single container.

## Included Tools

- **Kubernetes Tools**: kubectl, helm, kustomize, kubectx/kubens, stern
- **Cluster Exploration**: k9s, kubectl-neat, dive
- **Security**: trivy, kubeconform
- **Development**: telepresence
- **Utilities**: curl, wget, jq, yq, tcpdump, netcat, socat, and more

## Usage

### Run as a container in your cluster

```bash
kubectl run sherlock --rm -it --image=ghcr.io/yourusername/k8s-sherlock --restart=Never -- bash
```

---

Features
--------

* **Networking Tools**: Comes with `iproute2`, `iputils-ping`, `traceroute`, `netcat`, `dnsutils`, and `telnet`.
* **HTTP Tools**: `curl` and `wget` pre-installed for HTTP requests.
* **AWS Integration**: AWS CLI is installed for interacting with AWS services.
* **Docker CLI**: Perform Docker operations without leaving the pod.

---

Quick Start
-----------

### Prerequisites

* A Kubernetes cluster up and running
* kubectl installed and configured

### Deploy K8s-Sherlock Pod

bash

```bash
kubectl apply -f pod/sherlock.yaml --namespace=<namespace_name>
```

### Associate Service Account to Pod to AWS IAM role

bash

```bash
kubectl annotate service shelock-sa eks.amazonaws.com/role-arn=<YOUR_IAM_ROLE_ARN> --namespace=<namespace_name>

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

This project is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for details.
