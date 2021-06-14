FROM centos:7.9.2009
# Necessary setup
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-7
RUN echo "source scl_source enable devtoolset-7" >> /etc/bashrc
RUN source /etc/bashrc
RUN yum install -y autoconf automake cmake3 libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel dtc gtkwave vim-common virtualenv
RUN yum install -y epel-release
RUN rpm -U https://repo.ius.io/ius-release-el7.rpm
RUN yum install -y git224
# My setup
RUN yum install -y vim
RUN mkdir /workdir
WORKDIR /workdir
