ARG ARCH

#------------------------------------------------------------------------------------
#--------------------------build-----------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/focal/
FROM ${ARCH}ossrs/srs:ubuntu20-base4 as build

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG JOBS=2
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM, JOBS: $JOBS"

#------------------------------------------------------------------------------------
#--------------------------dist------------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/focal/
FROM ${ARCH}ubuntu:focal as dist

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG JOBS=2
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM, JOBS: $JOBS"

WORKDIR /tmp/srs

# Note that we can't do condional copy, because cmake has bin, docs and share files, so we copy the whole /usr/local
# directory or cmake will fail.
COPY --from=build /usr/local /usr/local
# Note that for armv7, the ffmpeg5-hevc-over-rtmp is actually ffmpeg5.
RUN ln -sf /usr/local/bin/ffmpeg5-hevc-over-rtmp /usr/local/bin/ffmpeg
# Note that the PATH has /usr/local/bin by default in ubuntu:focal.
#ENV PATH=$PATH:/usr/local/bin

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND=noninteractive

# Note that git is very important for codecov to discover the .codecov.yml
RUN apt update && \
    apt install -y aptitude gdb gcc g++ make patch unzip python \
        autoconf automake libtool pkg-config liblzma-dev curl net-tools \
        tcl

# To use if in RUN, see https://github.com/moby/moby/issues/7281#issuecomment-389440503
# Note that only exists issue like "/bin/sh: 1: [[: not found" for Ubuntu20, no such problem in CentOS7.
SHELL ["/bin/bash", "-c"]

# The cmake should be ready in base image. Use hash to clear cache for cmake,
# see https://stackoverflow.com/a/46805870/17679565
RUN hash -r && which cmake && cmake --version

# For https://github.com/google/sanitizers
RUN apt install -y libasan5

# Install cherrypy for HTTP hooks.
#ADD CherryPy-3.2.4.tar.gz2 /tmp
#RUN cd /tmp/CherryPy-3.2.4 && python setup.py install

ENV PATH=$PATH:/usr/local/go/bin
RUN if [[ -z $NO_GO ]]; then \
      cd /usr/local && \
      curl -L -O https://go.dev/dl/go1.16.12.linux-amd64.tar.gz && \
      tar xf go1.16.12.linux-amd64.tar.gz && \
      rm -f go1.16.12.linux-amd64.tar.gz; \
    fi

# For utest, the gtest. See https://github.com/google/googletest/releases/tag/release-1.11.0
ADD googletest-release-1.11.0.tar.gz /usr/local
RUN ln -sf /usr/local/googletest-release-1.11.0/googletest /usr/local/gtest

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

