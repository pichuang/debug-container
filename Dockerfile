# syntax=docker.io/docker/dockerfile-upstream:1.9.0
# check=error=true

FROM ubuntu:22.04
LABEL org.opencontainers.image.title="Debug Container" \
      org.opencontainers.image.authors="Phil Huang <phil.huang@microsoft.com>" \
      org.opencontainers.image.source="https://github.com/pichuang/debug-container" \
      org.opencontainers.image.description="A short and concise Container Troubleshooting Tool that is updated daily" \
      org.opencontainers.image.vendor="divecode.in" \
      org.opencontainers.image.url="ghcr.io/pichuang/debug-container:master" \
      org.opencontainers.image.documentation="https://github.com/pichuang/debug-container"

# Install core networking and debugging tools in one layer to minimize image size
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        python3 \
        python3-pip \
        iputils-ping \
        mtr-tiny \
        net-tools \
        htop \
        vim \
        git \
        dnsutils \
        iproute2 \
        netcat \
        wget \
        curl \
        tcpdump \
        sysstat \
        numactl \
        jq \
        iperf3 \
        procps \
        nmap \
        ethtool \
        sudo \
        tini \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set motd
COPY motd /etc/motd

# Create non-root user
RUN useradd -ms /bin/bash debuguser && \
    echo "debuguser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/debuguser && \
    chmod 0440 /etc/sudoers.d/debuguser && \
    echo "cat /etc/motd" >> /home/debuguser/.bashrc

EXPOSE 5566

# Use tini as init to properly handle signals
ENTRYPOINT ["/usr/bin/tini", "--"]

# Switch to non-root user
USER debuguser
WORKDIR /home/debuguser
ENV HOSTNAME=debug-container

# Add health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5566/ || exit 1

CMD ["/bin/bash", "-l"]
