FROM library/centos:7.6.1810
MAINTAINER Phil Huang <phil.huang@redhat.com>

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
        ethtool && \
    yum -y clean all

CMD ["/bin/bash"]
