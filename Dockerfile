# syntax=docker.io/docker/dockerfile-upstream:1.9.0
# check=error=true

ARG BASE_IMAGE=quay.io/centos/centos:stream9@sha256:b76d33c9df2e709b3a2d81ed2913c9deee814a9aabba16a57226b3a9fbea6d84
FROM ${BASE_IMAGE} AS builder
# hadolint ignore=DL3033
RUN yum -y install git ca-certificates && \
    yum -y clean all
RUN git clone https://github.com/upa/deadman.git /tmp/deadman && \
    git -C /tmp/deadman checkout 4746fd6aae3625b44e19cb3cac566e0544c04dc9 && \
    rm -rf /tmp/deadman/.git

FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.title="Debug Container" \
      org.opencontainers.image.authors="Phil Huang <phil.huang@microsoft.com>" \
      org.opencontainers.image.source="https://github.com/pichuang/debug-container" \
      org.opencontainers.image.description="A short and concise Container Troubleshooting Tool rebuilt weekly" \
      org.opencontainers.image.vendor="divecode.in" \
      org.opencontainers.image.url="ghcr.io/pichuang/debug-container:master" \
      org.opencontainers.image.documentation="https://github.com/pichuang/debug-container"

# Install packages and clean up in one layer
# hadolint ignore=DL3033
RUN yum -y install epel-release && \
    rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9 && \
    yum -y update && \
    yum -y --allowerasing install \
        python3.11 \
        python3.11-pip \
        iputils \
        mtr \
        net-tools \
        htop \
        vim \
        git \
        bind-utils \
        iproute \
        nmap-ncat \
        wget \
        curl \
        tcpdump \
        sysstat \
        numactl \
        hping3 \
        dnsperf \
        jq \
        speedtest-cli \
        iperf3 \
        procps-ng \
        nmap \
        ethtool && \
    yum -y clean all && \
    rm -rf /var/cache/yum && \
    rm -f /root/anaconda-ks.cfg /root/anaconda-post.log /root/original-ks.cfg /root/anaconda-post-nochroot.log

COPY --from=builder /tmp/deadman /root/deadman

# Set motd
COPY motd /etc/motd
RUN echo "cat /etc/motd" >> ~/.bashrc

EXPOSE 5566

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["bash", "-c", "echo healthy || exit 1"]

# hadolint ignore=DL3002
USER root
WORKDIR /root
ENV HOSTNAME=debug-container

CMD ["/bin/bash", "-l"]
