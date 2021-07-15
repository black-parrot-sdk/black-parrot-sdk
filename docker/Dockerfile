FROM centos:7.9.2009
# Necessary setup
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-7
RUN yum install -y autoconf automake libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel dtc gtkwave vim-common virtualenv
RUN yum install -y epel-release
RUN rpm -U https://repo.ius.io/ius-release-el7.rpm
RUN yum install -y git224
RUN yum install -y cmake3
# Install github CLI
RUN yum install -y wget
RUN wget https://github.com/cli/cli/releases/download/v1.12.1/gh_1.12.1_linux_amd64.rpm
RUN rpm -i gh_1.12.1_linux_amd64.rpm
# My setup
RUN yum install -y vim
RUN echo "source scl_source enable devtoolset-7" >> /etc/bashrc
RUN source /etc/bashrc
RUN mkdir /workdir
WORKDIR /workdir
