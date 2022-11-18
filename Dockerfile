
#------------------------------------------------------------------------------------
#--------------------------build-----------------------------------------------------
#------------------------------------------------------------------------------------
FROM ossrs/srs:dev6 as build

RUN yum install -y gcc gcc-c++ make patch sudo unzip perl zlib automake libtool \
    zlib-devel bzip2 bzip2-devel libxml2-devel \
    tcl cmake

# Libs path for app which depends on ssl, such as libsrt.
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/ssl/lib/pkgconfig

# Libs path for FFmpeg(depends on serval libs), or it fail with:
#       ERROR: speex not found using pkg-config
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig

# The cmake should be ready in base image.
RUN which cmake && cmake --version

# The ffmpeg and ssl should be ok.
RUN ls -lh /usr/local/bin/ffmpeg /usr/local/ssl

# Build SRS for cache, never install it.
#     SRS is d3441d23a For #2532: Windows: Replace ln by cp for windows. v5.0.87 (#3246)
# Pelease update this comment, if need to refresh the cached dependencies, like st/openssl/ffmpeg/libsrtp/libsrt etc.
RUN mkdir -p /usr/local/srs-cache
WORKDIR /usr/local/srs-cache
RUN git clone --depth=1 -b develop https://github.com/ossrs/srs.git
RUN cd srs/trunk && ./configure --jobs=${JOBS} --cxx11=off --cxx14=off && make -j${JOBS}
RUN du -sh /usr/local/srs-cache/srs/trunk/*

#------------------------------------------------------------------------------------
#--------------------------dist------------------------------------------------------
#------------------------------------------------------------------------------------
FROM centos:6 as dist

WORKDIR /tmp/srs

# Note that we can't do condional copy, so we copy the whole /usr/local directory.
COPY --from=build /usr/local /usr/local

# To enable yum for CentOS6
ADD etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
ADD etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo
RUN yum makecache

# Note that git is very important for codecov to discover the .codecov.yml
RUN yum install -y gcc gcc-c++ make net-tools gdb lsof tree dstat redhat-lsb unzip zip git \
    nasm yasm perf strace sysstat ethtool libtool \
    tcl cmake

# For GCP/pprof/gperf, see https://winlin.blog.csdn.net/article/details/53503869
RUN yum install -y graphviz

# Install cherrypy for HTTP hooks.
ADD CherryPy-3.2.4.tar.gz2 /tmp
RUN cd /tmp/CherryPy-3.2.4 && python setup.py install

ENV PATH $PATH:/usr/local/go/bin
RUN cd /usr/local && \
    curl -L -O https://go.dev/dl/go1.16.12.linux-amd64.tar.gz && \
    tar xf go1.16.12.linux-amd64.tar.gz && \
    rm -f go1.16.12.linux-amd64.tar.gz

# For utest, the gtest.
ADD googletest-release-1.6.0.tar.gz /usr/local
RUN ln -sf /usr/local/googletest-release-1.6.0 /usr/local/gtest

