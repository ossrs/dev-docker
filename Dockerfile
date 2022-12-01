ARG ARCH

#------------------------------------------------------------------------------------
#--------------------------build-----------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/focal/
FROM ${ARCH}ossrs/srs:ubuntu20 as build

ARG BUILDPLATFORM
ARG TARGETPLATFORM
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM"

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND noninteractive

# Update the mirror from aliyun, @see https://segmentfault.com/a/1190000022619136
#ADD sources.list /etc/apt/sources.list
#RUN apt-get update

RUN apt-get update && \
    apt-get install -y aptitude gcc g++ make patch unzip python \
        autoconf automake libtool pkg-config libxml2-dev zlib1g-dev \
        liblzma-dev libzip-dev libbz2-dev tcl

# Libs path for app which depends on ssl, such as libsrt.
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/ssl/lib/pkgconfig

# Libs path for FFmpeg(depends on serval libs), or it fail with:
#       ERROR: speex not found using pkg-config
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig

# To use if in RUN, see https://github.com/moby/moby/issues/7281#issuecomment-389440503
# Note that only exists issue like "/bin/sh: 1: [[: not found" for Ubuntu20, no such problem in CentOS7.
SHELL ["/bin/bash", "-c"]

# The cmake should be ready in base image.
RUN which cmake && cmake --version

# The ffmpeg and ssl should be ok.
RUN ls -lh /usr/local/bin/ffmpeg /usr/local/ssl

# Build SRS for cache, never install it.
#     SRS is 79d096ae9 Merge branch 5.0.98 into develop
# Pelease update this comment, if need to refresh the cached dependencies, like st/openssl/ffmpeg/libsrtp/libsrt etc.
RUN mkdir -p /usr/local/srs-cache
WORKDIR /usr/local/srs-cache
RUN apt-get install -y git && git clone --depth=1 -b develop https://github.com/ossrs/srs.git
RUN cd srs/trunk && ./configure && make
RUN du -sh /usr/local/srs-cache/srs/trunk/*

#------------------------------------------------------------------------------------
#--------------------------dist------------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/focal/
FROM ${ARCH}ubuntu:focal as dist

ARG BUILDPLATFORM
ARG TARGETPLATFORM
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM"

WORKDIR /tmp/srs

# Note that we can't do condional copy, because cmake has bin, docs and share files, so we copy the whole /usr/local
# directory or cmake will fail.
COPY --from=build /usr/local /usr/local
# Note that for armv7, the ffmpeg5-hevc-over-rtmp is actually ffmpeg5.
RUN ln -sf /usr/local/bin/ffmpeg5-hevc-over-rtmp /usr/local/bin/ffmpeg
# Note that the PATH has /usr/local/bin by default in ubuntu:focal.
#ENV PATH=$PATH:/usr/local/bin

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND noninteractive

# Note that git is very important for codecov to discover the .codecov.yml
RUN apt-get update && \
    apt-get install -y aptitude gdb gcc g++ make patch unzip python \
        autoconf automake libtool pkg-config libxml2-dev liblzma-dev curl net-tools \
        tcl

# To use if in RUN, see https://github.com/moby/moby/issues/7281#issuecomment-389440503
# Note that only exists issue like "/bin/sh: 1: [[: not found" for Ubuntu20, no such problem in CentOS7.
SHELL ["/bin/bash", "-c"]

# The cmake should be ready in base image.
RUN which cmake && cmake --version

# Install cherrypy for HTTP hooks.
#ADD CherryPy-3.2.4.tar.gz2 /tmp
#RUN cd /tmp/CherryPy-3.2.4 && python setup.py install

# We already installed go and gtest in /usr/local.
#ENV PATH $PATH:/usr/local/go/bin
#RUN if [[ -z $NO_GO ]]; then \
#      cd /usr/local && \
#      curl -L -O https://go.dev/dl/go1.16.12.linux-amd64.tar.gz && \
#      tar xf go1.16.12.linux-amd64.tar.gz && \
#      rm -f go1.16.12.linux-amd64.tar.gz; \
#    fi
#
#ADD googletest-release-1.6.0.tar.gz /usr/local
#RUN ln -sf /usr/local/googletest-release-1.6.0 /usr/local/gtest

# Install 32bits adapter for crossbuild.
RUN if [[ $TARGETPLATFORM != 'linux/arm/v7' && $TARGETPLATFORM != 'linux/arm64/v8' && $TARGETPLATFORM != 'linux/arm64' ]]; then \
        apt-get -y install lib32z1-dev; \
    fi

# For cross-build: https://github.com/ossrs/srs/wiki/v4_EN_SrsLinuxArm#ubuntu-cross-build-srs
RUN if [[ $TARGETPLATFORM != 'linux/arm/v7' && $TARGETPLATFORM != 'linux/arm64/v8' && $TARGETPLATFORM != 'linux/arm64' ]]; then \
      apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
        gcc-aarch64-linux-gnu g++-aarch64-linux-gnu; \
    fi

# Update the mirror from aliyun, @see https://segmentfault.com/a/1190000022619136
#ADD sources.list /etc/apt/sources.list
#RUN apt-get update


