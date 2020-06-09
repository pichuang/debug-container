FROM library/centos:7.8.2003
MAINTAINER Phil Huang <phil.huang@redhat.com>

# Install packages
RUN yum -y install epel-release && \
    rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
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
ADD motd /etc/motd
RUN echo "cat /etc/motd" >> ~/.bashrc

CMD ["/bin/bash", "-l"]
