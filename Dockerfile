FROM debian:bookworm-slim

LABEL maintainer="Arun Sanna"
LABEL org.opencontainers.image.title="k8s-sherlock"
LABEL org.opencontainers.image.description="Kubernetes debugging and troubleshooting toolkit"
LABEL org.opencontainers.image.source="https://github.com/arunsanna/k8s-sherlock"
LABEL org.opencontainers.image.licenses="MPL-2.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Auto-populated by docker buildx; falls back for plain docker build
ARG TARGETARCH

# Layer 1: System packages (apt-get)
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    git \
    vim \
    procps \
    net-tools \
    dnsutils \
    iputils-ping \
    netcat-openbsd \
    tcpdump \
    iproute2 \
    jq \
    python3 \
    unzip \
    socat \
    fzf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Binary downloads (kubectl, stern, kustomize, yq, kubeconform, dive, telepresence, trivy)
RUN set -eux; \
    ARCH="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    # --- kubectl ---
    KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"; \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"; \
    chmod +x kubectl && mv kubectl /usr/local/bin/; \
    # --- stern ---
    STERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -c 2-); \
    curl -L -o stern.tar.gz "https://github.com/stern/stern/releases/latest/download/stern_${STERN_VERSION}_linux_${ARCH}.tar.gz"; \
    tar -xzf stern.tar.gz stern && chmod +x stern && mv stern /usr/local/bin/; \
    rm -f stern.tar.gz LICENSE; \
    # --- kustomize ---
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash; \
    mv kustomize /usr/local/bin/; \
    # --- yq ---
    wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}"; \
    chmod +x /usr/local/bin/yq; \
    # --- kubeconform ---
    KUBECONFORM_VERSION=$(curl -s https://api.github.com/repos/yannh/kubeconform/releases/latest | grep tag_name | cut -d '"' -f 4); \
    wget -q "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-${ARCH}.tar.gz"; \
    tar xzf "kubeconform-linux-${ARCH}.tar.gz" kubeconform && mv kubeconform /usr/local/bin/; \
    rm -f "kubeconform-linux-${ARCH}.tar.gz"; \
    # --- dive ---
    DIVE_VERSION=$(curl -s https://api.github.com/repos/wagoodman/dive/releases/latest | grep tag_name | cut -d '"' -f 4); \
    curl -OL "https://github.com/wagoodman/dive/releases/download/${DIVE_VERSION}/dive_${DIVE_VERSION#v}_linux_${ARCH}.deb"; \
    dpkg -i "dive_${DIVE_VERSION#v}_linux_${ARCH}.deb"; \
    rm -f "dive_${DIVE_VERSION#v}_linux_${ARCH}.deb"; \
    # --- telepresence ---
    curl -fL "https://app.getambassador.io/download/tel2/linux/${ARCH}/latest/telepresence" -o /usr/local/bin/telepresence; \
    chmod a+x /usr/local/bin/telepresence; \
    # --- trivy ---
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list; \
    apt-get update && apt-get install -y trivy; \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Layer 3: Tools with special installers (helm, k9s, kubectx, krew)
RUN set -eux; \
    # --- helm ---
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
    # --- k9s ---
    curl -sS https://webinstall.dev/k9s | bash; \
    # --- kubectx/kubens ---
    git clone https://github.com/ahmetb/kubectx /opt/kubectx; \
    ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx; \
    ln -s /opt/kubectx/kubens /usr/local/bin/kubens; \
    # --- krew ---
    cd "$(mktemp -d)"; \
    OS="$(uname | tr '[:upper:]' '[:lower:]')"; \
    KREW_ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"; \
    KREW="krew-${OS}_${KREW_ARCH}"; \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"; \
    tar zxvf "${KREW}.tar.gz"; \
    ./"${KREW}" install krew; \
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /etc/profile.d/krew.sh; \
    rm -rf "$(pwd)"

# Layer 4: Krew plugins
RUN /bin/bash -c "export PATH=\"/root/.krew/bin:\$PATH\" && \
    kubectl krew install ctx ns neat"

# Layer 5: User setup (sherlock user, krew copy, app dir)
RUN groupadd -r sherlock && useradd -r -g sherlock -m -s /bin/bash sherlock \
    && cp -rL /root/.krew /home/sherlock/.krew \
    && chown -R sherlock:sherlock /home/sherlock/.krew \
    && echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /home/sherlock/.bashrc \
    && mkdir -p /app && chown sherlock:sherlock /app

# Switch to non-root user
USER sherlock

# Set krew in PATH for the sherlock user
ENV PATH="/home/sherlock/.krew/bin:${PATH}"

WORKDIR /app

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD kubectl version --client --output=yaml > /dev/null 2>&1 || exit 1

ENTRYPOINT ["/bin/bash"]
