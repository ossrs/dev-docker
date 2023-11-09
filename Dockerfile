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
#     5.0release 316f4641a Don't compile libopus when enable sys-ffmpeg. v5.0.198 (#3851)
#     develop    4372e32f7 Don't compile libopus when enable sys-ffmpeg. v5.0.198 v6.0.98 (#3851)
# Pelease update this comment, if need to refresh the cached dependencies, like st/openssl/ffmpeg/libsrtp/libsrt etc.
RUN mkdir -p /usr/local/srs-cache
# Note that cygwin build cache files for SRS in .github/workflows/release.yml file.
#     ./configure --utest=on
ADD srs.tar.bz2 /usr/local/srs-cache
RUN ls -lh /usr/local/srs-cache && \
    ls -lh /usr/local/srs-cache/srs && \
    du -sh /usr/local/srs-cache/srs/trunk/*

#------------------------------------------------------------------------------------
#--------------------------dist------------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/focal/
FROM ${ARCH}ubuntu:focal as dist

ARG BUILDPLATFORM
ARG TARGETPLATFORM
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM"

WORKDIR /tmp/srs

# Note that we can't do condional copy, so we copy the whole /usr/local directory.
COPY --from=build /usr/local /usr/local

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND noninteractive

# Note that git is very important for codecov to discover the .codecov.yml
RUN apt-get update && \
    apt-get install -y aptitude gdb gcc g++ make patch unzip python \
        autoconf automake libtool pkg-config libxml2-dev liblzma-dev curl net-tools \
        tcl cmake

# The cmake should be ready in base image.
RUN which cmake && cmake --version


