# https://docs.docker.com/engine/reference/builder/#arg
# @remark Please never modify it, the auto/release.sh will update it automatically.
ARG url=https://github.com/ossrs/srs.git
ARG repo=ossrs/srs:dev

FROM ${repo}
ARG url

# Install required tools.
RUN yum install -y gcc gcc-c++ make net-tools gdb lsof tree dstat redhat-lsb unzip zip git \
    nasm perf strace sysstat ethtool libtool

# Clone the latest code.
RUN cd / && git clone --branch develop ${url} srs

WORKDIR /srs/trunk
CMD ["bash", "-c", "ls -lh && pwd"]
