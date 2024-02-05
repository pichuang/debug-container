FROM quay.io/centos/centos:stream8
LABEL org.opencontainers.image.title = "Debug Container" \
      org.opencontainers.image.authors = "Phil Huang <phil.huang@microsoft.com>" \
      org.opencontainers.image.source = "https://github.com/pichuang/debug-container" \
      org.opencontainers.image.description = "A short and concise Container Troubleshooting Tool that is updated daily" \
      org.opencontainers.image.vendor = "divecode.in" \
      org.opencontainers.image.url = "ghcr.io/pichuang/debug-container:master" \
      org.opencontainers.image.documentation = "https://github.com/pichuang/debug-container"

# Install packages
RUN yum -y install epel-release && \
    rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8 && \
    yum -y update && \
    yum -y install \
        sudo \
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
        ethtool && \
    yum -y clean all

RUN git clone https://github.com/upa/deadman.git /root/deadman

RUN rm /root/anaconda-ks.cfg && \
    rm /root/anaconda-post.log && \
    rm /root/original-ks.cfg

# Set motd
COPY motd /etc/motd
RUN echo "cat /etc/motd" >> ~/.bashrc

EXPOSE 5566

WORKDIR /root

CMD ["/bin/bash", "-l"]
