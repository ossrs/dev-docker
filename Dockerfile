ARG ARCH

#------------------------------------------------------------------------------------
#--------------------------build-----------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/focal/
FROM ${ARCH}ubuntu:focal as build

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
        liblzma-dev libzip-dev libbz2-dev tcl cmake

# Libs path for app which depends on ssl, such as libsrt.
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/ssl/lib/pkgconfig

# Libs path for FFmpeg(depends on serval libs), or it fail with:
#       ERROR: speex not found using pkg-config
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig

# Openssl 1.1.* for SRS.
ADD openssl-1.1.1j.tar.bz2 /tmp
RUN cd /tmp/openssl-1.1.1j && \
   ./config -no-shared -no-threads --prefix=/usr/local/ssl && make && make install_sw

# Openssl 1.0.* for SRS.
#ADD openssl-OpenSSL_1_0_2u.tar.gz /tmp
#RUN cd /tmp/openssl-OpenSSL_1_0_2u && \
#    ./config -no-shared -no-threads --prefix=/usr/local/ssl && make && make install_sw

# For FFMPEG
ADD nasm-2.14.tar.bz2 /tmp
RUN cd /tmp/nasm-2.14 && ./configure && make && make install
# For aac
ADD fdk-aac-2.0.2.tar.gz /tmp
RUN cd /tmp/fdk-aac-2.0.2 && bash autogen.sh && CXXFLAGS=-Wno-narrowing ./configure --disable-shared && make && make install
# For mp3, see https://sourceforge.net/projects/lame/
ADD  lame-3.100.tar.gz /tmp
RUN cd /tmp/lame-3.100 && ./configure --disable-shared && make && make install
# For libx264
ADD x264-snapshot-20181116-2245.tar.bz2 /tmp
RUN cd /tmp/x264-snapshot-20181116-2245 && ./configure --disable-shared --disable-cli --enable-static --enable-pic && make && make install
# The libsrt for SRS, which depends on openssl.
ADD srt-1.4.1.tar.gz /tmp
RUN if [[ $TARGETPLATFORM != 'linux/arm/v7' ]]; then \
      cd /tmp/srt-1.4.1 && \
      ./configure --enable-shared=0 --enable-static --disable-app --enable-c++11=0 && \
      make && make install && \
      FFMPEG_OPTIONS="--enable-libsrt"; \
    fi

# Build FFmpeg, static link libraries.
ADD ffmpeg-4.2.1.tar.bz2 /tmp
RUN cd /tmp/ffmpeg-4.2.1 && ./configure --enable-pthreads --extra-libs=-lpthread \
        --enable-gpl --enable-nonfree \
        --enable-postproc --enable-bzlib --enable-zlib \
        --enable-libx264 --enable-libmp3lame --enable-libfdk-aac \
        --enable-libxml2 --enable-demuxer=dash \
        ${FFMPEG_OPTIONS} --pkg-config-flags='--static' && \
    make && make install && echo "FFMPEG build and install successfully"

#------------------------------------------------------------------------------------
#--------------------------dist------------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/focal/
FROM ${ARCH}ubuntu:focal as dist

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG NO_GO
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM, NO_GO: $NO_GO"

WORKDIR /tmp/srs

COPY --from=build /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=build /usr/local/bin/ffprobe /usr/local/bin/ffprobe
COPY --from=build /usr/local/ssl /usr/local/ssl

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND noninteractive

# Note that git is very important for codecov to discover the .codecov.yml
RUN apt-get update && \
    apt-get install -y aptitude gdb gcc g++ make patch unzip python \
        autoconf automake libtool pkg-config libxml2-dev liblzma-dev curl net-tools \
        tcl cmake

# Install cherrypy for HTTP hooks.
ADD CherryPy-3.2.4.tar.gz2 /tmp
RUN cd /tmp/CherryPy-3.2.4 && python setup.py install

ENV PATH $PATH:/usr/local/go/bin
RUN if [[ -z $NO_GO ]]; then \
      cd /usr/local && \
      curl -L -O https://go.dev/dl/go1.16.12.linux-amd64.tar.gz && \
      tar xf go1.16.12.linux-amd64.tar.gz && \
      rm -f go1.16.12.linux-amd64.tar.gz; \
    fi

# For utest, the gtest.
ADD googletest-release-1.6.0.tar.gz /usr/local
RUN ln -sf /usr/local/googletest-release-1.6.0 /usr/local/gtest

# For cross-build: https://github.com/ossrs/srs/wiki/v4_EN_SrsLinuxArm#ubuntu-cross-build-srs
RUN if [[ $TARGETPLATFORM != 'linux/arm/v7' && $TARGETPLATFORM != 'linux/arm64/v8' ]]; then \
      apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
      gcc-aarch64-linux-gnu g++-aarch64-linux-gnu; \
    fi

# Update the mirror from aliyun, @see https://segmentfault.com/a/1190000022619136
#ADD sources.list /etc/apt/sources.list
#RUN apt-get update

