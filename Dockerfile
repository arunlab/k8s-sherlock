# Updated to latest Debian stable release
FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools and dependencies
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
    python3-pip \
    python3-venv \
    unzip \
    socat \
    fzf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS (for Claude Code and modern tooling)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl (latest stable)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && kubectl version --client

# Install Helm (latest)
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && helm version

# Install k9s (latest)
RUN K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && curl -sL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" | tar xz -C /tmp \
    && mv /tmp/k9s /usr/local/bin/ \
    && chmod +x /usr/local/bin/k9s

# Install kubectx and kubens (latest)
RUN KUBECTX_VERSION=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && curl -sL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_x86_64.tar.gz" | tar xz -C /tmp \
    && curl -sL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_x86_64.tar.gz" | tar xz -C /tmp \
    && mv /tmp/kubectx /usr/local/bin/ \
    && mv /tmp/kubens /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

# Install krew (latest)
RUN set -ex; \
    cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf "${KREW}.tar.gz" && \
    ./"${KREW}" install krew && \
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /etc/profile.d/krew.sh && \
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /root/.bashrc

# Install stern (latest)
RUN STERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && curl -sL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64.tar.gz" | tar xz -C /tmp \
    && mv /tmp/stern /usr/local/bin/ \
    && chmod +x /usr/local/bin/stern

# Install kustomize (latest)
RUN KUSTOMIZE_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/kustomize\///') \
    && curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp \
    && mv /tmp/kustomize /usr/local/bin/ \
    && chmod +x /usr/local/bin/kustomize

# Install yq (latest)
RUN YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq

# Install trivy (latest via apt repository)
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y trivy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && trivy --version

# Install kubeconform (latest)
RUN KUBECONFORM_VERSION=$(curl -s https://api.github.com/repos/yannh/kubeconform/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && wget -q "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
    && tar xzf kubeconform-linux-amd64.tar.gz \
    && mv kubeconform /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubeconform \
    && rm kubeconform-linux-amd64.tar.gz

# Install kubectl plugins via krew
RUN /bin/bash -c "export PATH=\"/root/.krew/bin:\$PATH\" && \
    kubectl krew update && \
    kubectl krew install ctx ns neat"

# Install dive (container image explorer, latest)
RUN DIVE_VERSION=$(curl -s https://api.github.com/repos/wagoodman/dive/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && ARCH=$(dpkg --print-architecture) \
    && curl -OL "https://github.com/wagoodman/dive/releases/download/${DIVE_VERSION}/dive_${DIVE_VERSION#v}_linux_${ARCH}.deb" \
    && dpkg -i "dive_${DIVE_VERSION#v}_linux_${ARCH}.deb" \
    && rm "dive_${DIVE_VERSION#v}_linux_${ARCH}.deb"

# Install telepresence (latest)
RUN TELEPRESENCE_VERSION=$(curl -s https://api.github.com/repos/telepresenceio/telepresence/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && curl -fL "https://app.getambassador.io/download/tel2oss/releases/download/${TELEPRESENCE_VERSION}/telepresence-linux-amd64" -o /usr/local/bin/telepresence \
    && chmod a+x /usr/local/bin/telepresence

# Install GitHub CLI (gh) - latest
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && gh --version

# Install GitHub Copilot CLI (as a code assistant similar to Codex)
RUN npm install -g @githubnext/github-copilot-cli \
    && npm cache clean --force

# Install Claude Code CLI - Anthropic's official Claude CLI
RUN npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

# Install additional useful tools
# Install lazydocker (Docker management TUI)
RUN LAZYDOCKER_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && curl -sL "https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION#v}_Linux_x86_64.tar.gz" | tar xz -C /tmp \
    && mv /tmp/lazydocker /usr/local/bin/ \
    && chmod +x /usr/local/bin/lazydocker

# Install k1s (Kubernetes cluster visualization)
RUN K1S_VERSION=$(curl -s https://api.github.com/repos/weibeld/k1s/releases/latest | grep tag_name | cut -d '"' -f 4 2>/dev/null || echo "v0.0.3") \
    && curl -sL "https://github.com/weibeld/k1s/releases/download/${K1S_VERSION}/k1s-linux-amd64" -o /usr/local/bin/k1s \
    && chmod +x /usr/local/bin/k1s || true

# Install kubeval (Kubernetes manifest validation)
RUN KUBEVAL_VERSION=$(curl -s https://api.github.com/repos/instrumenta/kubeval/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && wget -q "https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" \
    && tar xzf kubeval-linux-amd64.tar.gz \
    && mv kubeval /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubeval \
    && rm kubeval-linux-amd64.tar.gz

# Make krew available in PATH by default
ENV PATH="/root/.krew/bin:${PATH}"

# Create working directory
WORKDIR /app

# Add helpful aliases and configurations
RUN echo 'alias k=kubectl' >> /root/.bashrc \
    && echo 'alias kgp="kubectl get pods"' >> /root/.bashrc \
    && echo 'alias kgs="kubectl get svc"' >> /root/.bashrc \
    && echo 'alias kgd="kubectl get deploy"' >> /root/.bashrc \
    && echo 'alias kl="kubectl logs"' >> /root/.bashrc \
    && echo 'alias kd="kubectl describe"' >> /root/.bashrc \
    && echo 'complete -F __start_kubectl k' >> /root/.bashrc

# Set entrypoint to bash
ENTRYPOINT ["/bin/bash"]
