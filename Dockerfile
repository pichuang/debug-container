FROM quay.io/centos/centos:stream8
LABEL org.opencontainers.image.authors="Phil Huang <phil.huang@microsoft.com>"

# Install packages
RUN yum -y install epel-release && \
    rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8 && \
    yum -y update && \
    yum -y install \
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
        ethtool && \
    yum -y clean all

# Set motd
COPY motd /etc/motd
RUN echo "cat /etc/motd" >> ~/.bashrc

CMD ["/bin/bash", "-l"]
