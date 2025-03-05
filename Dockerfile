FROM debian:bullseye-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools
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
    netcat \
    tcpdump \
    iproute2 \
    jq \
    python3 \
    python3-pip \
    unzip \
    socat \
    fzf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k9s
RUN curl -sS https://webinstall.dev/k9s | bash

# Install kubectx and kubens
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx \
    && ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install krew
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

# Install stern
RUN curl -L -o stern.tar.gz https://github.com/stern/stern/releases/latest/download/stern_$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -c 2-)_linux_amd64.tar.gz \
    && tar -xzf stern.tar.gz \
    && chmod +x stern \
    && mv stern /usr/local/bin/ \
    && rm stern.tar.gz LICENSE

# Install kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && mv kustomize /usr/local/bin/

# Install yq
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

# Install trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y trivy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install kubeconform
RUN KUBECONFORM_VERSION=$(curl -s https://api.github.com/repos/yannh/kubeconform/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && wget -q "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
    && tar xzf kubeconform-linux-amd64.tar.gz \
    && mv kubeconform /usr/local/bin/ \
    && rm kubeconform-linux-amd64.tar.gz

# Install kubectl plugins via krew
RUN /bin/bash -c "export PATH=\"/root/.krew/bin:\$PATH\" && \
    kubectl krew install ctx ns neat"

# Install dive (container image explorer) directly instead of as krew plugin
RUN DIVE_VERSION=$(curl -s https://api.github.com/repos/wagoodman/dive/releases/latest | grep tag_name | cut -d '"' -f 4) \
    && ARCH=$(dpkg --print-architecture) \
    && curl -OL https://github.com/wagoodman/dive/releases/download/${DIVE_VERSION}/dive_${DIVE_VERSION#v}_linux_${ARCH}.deb \
    && dpkg -i dive_${DIVE_VERSION#v}_linux_${ARCH}.deb \
    && rm dive_${DIVE_VERSION#v}_linux_${ARCH}.deb

# Make krew available in PATH by default
ENV PATH="/root/.krew/bin:${PATH}"

# Install telepresence for local development
RUN curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence -o /usr/local/bin/telepresence \
    && chmod a+x /usr/local/bin/telepresence

# Create working directory
WORKDIR /app

# Set entrypoint to bash
ENTRYPOINT ["/bin/bash"]