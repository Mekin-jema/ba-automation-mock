FROM jenkins/jenkins:lts-jdk17

USER root

ENV DEBIAN_FRONTEND=noninteractive

# ===============================
# Install base tools needed for this repo
# ===============================
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    ca-certificates-java \
    curl \
    git \
    gnupg \
    lsb-release \
    docker.io \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    && update-ca-certificates \
    && /var/lib/dpkg/info/ca-certificates-java.postinst configure \
    && rm -rf /var/lib/apt/lists/*

# Debian packaging can provide dockerd without the docker CLI in some base images.
# Install docker-cli only when docker command is missing, then assert it exists.
RUN if ! command -v docker >/dev/null 2>&1; then \
            apt-get update; \
            apt-get install -y --no-install-recommends docker-cli; \
            rm -rf /var/lib/apt/lists/*; \
        fi \
        && command -v docker >/dev/null 2>&1

# ===============================
# Docker permissions
# ===============================
RUN groupadd -f docker \
    && usermod -aG docker jenkins

# ===============================
# Set up workspace for this repo
# ===============================
WORKDIR /workspace

# ===============================
# Minimal Jenkins plugins
# ===============================
USER jenkins

RUN mkdir -p /var/jenkins_home && \
    chmod 755 /var/jenkins_home && \
    mkdir -p /home/jenkins && \
    echo 'JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts -Djavax.net.ssl.trustStorePassword=changeit' >> /home/jenkins/.bashrc

RUN jenkins-plugin-cli --plugins \
    git \
    workflow-aggregator

# ===============================
# Cleanup plugin cache (important)
# ===============================
RUN rm -rf /var/jenkins_home/.cache || true

EXPOSE 8080 50000