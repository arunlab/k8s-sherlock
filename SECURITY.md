# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in K8s-Sherlock, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, please email: **security@arunlabs.com**

Include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation within 7 days for critical issues.

## Security Practices

### Image Build

- Base image: `debian:bookworm-slim` (minimal attack surface)
- Non-root user: container runs as `sherlock` (UID 999) — never as root
- Tools installed from official sources and package repositories
- CI pipeline runs [Trivy](https://github.com/aquasecurity/trivy) vulnerability scanning on every build
- CRITICAL and HIGH severity vulnerabilities **fail the build** (enforced gate, not just reported)
- Pod manifest includes `seccompProfile: RuntimeDefault` to restrict syscalls

### Container Runtime

- The container is intended for debugging sessions, not long-running production workloads
- Use Kubernetes RBAC to limit the ServiceAccount permissions granted to the sherlock pod
- Avoid mounting sensitive secrets or host paths into the container unless necessary
- Consider using network policies to restrict the pod's network access

### Recommendations

- Pin to a specific image tag (e.g., `arunsanna/k8s-sherlock:v1.0.0`) rather than `latest` for reproducible environments
- Rebuild the image regularly to pick up upstream security patches
- Review the [pod manifest](pod/sherlock.yml) and adjust resource limits and tolerations for your environment

## Supported Versions

| Version | Supported |
| ------- | --------- |
| latest  | Yes       |
| < 1.0   | No        |
