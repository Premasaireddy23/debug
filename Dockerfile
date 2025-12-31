# debug-aks-azcli.Dockerfile
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG KUBECTL_VERSION=1.29.8

# Optional: pin Prisma CLI version if you want (otherwise leave as latest)
ARG PRISMA_VERSION=latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget bash vim nano less jq git unzip gnupg lsb-release \
    iproute2 iputils-ping dnsutils netcat-openbsd tcpdump traceroute mtr-tiny \
    procps lsof strace socat \
    postgresql-client \
 && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ jammy main" \
      > /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends azure-cli && \
    rm -rf /var/lib/apt/lists/*

# yq
RUN wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
 && chmod +x /usr/local/bin/yq

# kubectl
RUN curl -fsSL -o /usr/local/bin/kubectl \
    "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && chmod +x /usr/local/bin/kubectl

# -----------------------------
# Node.js + Prisma Studio
# -----------------------------

# NodeSource repo for Node 20
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
 && mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update && apt-get install -y --no-install-recommends nodejs \
 && node -v && npm -v && npx -v \
 && rm -rf /var/lib/apt/lists/*

# Install Prisma CLI globally (gives `prisma` command)
RUN npm config set update-notifier false && \
    npm i -g prisma@${PRISMA_VERSION} && \
    prisma -v

EXPOSE 5555

RUN useradd -ms /bin/bash debug && mkdir -p /work && chown -R debug:debug /work
WORKDIR /work
USER debug

CMD ["/bin/bash"]
