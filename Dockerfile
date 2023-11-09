
#------------------------------------------------------------------------------------
#--------------------------build-----------------------------------------------------
#------------------------------------------------------------------------------------
FROM ossrs/srs:dev-gcc7 as build

ARG JOBS=2
RUN echo "JOBS: $JOBS"

RUN yum install -y gcc gcc-c++ make patch sudo unzip perl zlib automake libtool \
    zlib-devel bzip2 bzip2-devel libxml2-devel \
    tcl cmake

# Libs path for app which depends on ssl, such as libsrt.
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/ssl/lib/pkgconfig

# Libs path for FFmpeg(depends on serval libs), or it fail with:
#       ERROR: speex not found using pkg-config
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig

# Build SRS for cache, never install it.
#     5.0release 316f4641a Don't compile libopus when enable sys-ffmpeg. v5.0.198 (#3851)
#     develop    4372e32f7 Don't compile libopus when enable sys-ffmpeg. v5.0.198 v6.0.98 (#3851)
# Pelease update this comment, if need to refresh the cached dependencies, like st/openssl/ffmpeg/libsrtp/libsrt etc.
RUN mkdir -p /usr/local/srs-cache
RUN cd /usr/local/srs-cache && git clone https://github.com/ossrs/srs.git
# Setup the SRS trunk as workdir.
WORKDIR /usr/local/srs-cache/srs/trunk
# Build SRS 5.0
RUN git checkout 5.0release
RUN scl enable devtoolset-7 -- ./configure --jobs=${JOBS} --sanitizer=off
RUN scl enable devtoolset-7 -- make -j${JOBS}
# Build SRS 6.0
RUN git checkout develop
RUN scl enable devtoolset-7 -- ./configure --jobs=${JOBS} --sanitizer=off --ffmpeg-opus=on
RUN scl enable devtoolset-7 -- make -j${JOBS}

#------------------------------------------------------------------------------------
#--------------------------dist------------------------------------------------------
#------------------------------------------------------------------------------------
FROM centos:7 as dist

WORKDIR /tmp/srs

# Note that we can't do condional copy, because cmake has bin, docs and share files, so we copy the whole /usr/local
# directory or cmake will fail.
COPY --from=build /usr/local /usr/local
# Note that for armv7, the ffmpeg5-hevc-over-rtmp is actually ffmpeg5.
RUN ln -sf /usr/local/bin/ffmpeg5-hevc-over-rtmp /usr/local/bin/ffmpeg
# Note that the PATH has /usr/local/bin by default in ubuntu:focal.
#ENV PATH=$PATH:/usr/local/bin

# Note that git is very important for codecov to discover the .codecov.yml
RUN yum install -y gcc gcc-c++ make net-tools gdb lsof tree dstat redhat-lsb unzip zip git \
    nasm yasm perf strace sysstat ethtool libtool \
    tcl cmake

# For GCP/pprof/gperf, see https://winlin.blog.csdn.net/article/details/53503869
RUN yum install -y graphviz

# Install cherrypy for HTTP hooks.
#ADD CherryPy-3.2.4.tar.gz2 /tmp
#RUN cd /tmp/CherryPy-3.2.4 && python setup.py install

ENV PATH $PATH:/usr/local/go/bin
RUN cd /usr/local && \
    curl -L -O https://go.dev/dl/go1.16.12.linux-amd64.tar.gz && \
    tar xf go1.16.12.linux-amd64.tar.gz && \
    rm -f go1.16.12.linux-amd64.tar.gz

# For utest, the gtest. See https://github.com/google/googletest/releases/tag/release-1.11.0
ADD googletest-release-1.11.0.tar.gz /usr/local
RUN ln -sf /usr/local/googletest-release-1.11.0/googletest /usr/local/gtest

# Upgrade to GCC 7 for gtest, see https://stackoverflow.com/a/39731134/17679565
RUN yum install -y centos-release-scl && yum install -y devtoolset-7-gcc* 

# For address sanitizer, see https://github.com/google/sanitizers
RUN yum install -y libasan devtoolset-7-libasan-devel

# See https://austindewey.com/2019/03/26/enabling-software-collections-binaries-on-a-docker-image/
# scl enable devtoolset-7 bash
COPY scl_enable /usr/bin/scl_enable
ENV BASH_ENV="/usr/bin/scl_enable" \
    ENV="/usr/bin/scl_enable" \
    PROMPT_COMMAND=". /usr/bin/scl_enable"


