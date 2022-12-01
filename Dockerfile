
#------------------------------------------------------------------------------------
#--------------------------build-----------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/xenial/
FROM ubuntu:xenial as build

ARG JOBS=2
RUN echo "JOBS: $JOBS"

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND noninteractive

# Update the mirror from aliyun, @see https://segmentfault.com/a/1190000022619136
#ADD sources.list /etc/apt/sources.list
#RUN apt-get update

RUN apt-get update && \
    apt-get install -y aptitude gcc g++ make patch unzip python \
        autoconf automake libtool pkg-config zlib1g-dev \
        liblzma-dev libzip-dev libbz2-dev tcl

# Libs path for app which depends on ssl, such as libsrt.
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/ssl/lib/pkgconfig

# Libs path for FFmpeg(depends on serval libs), or it fail with:
#       ERROR: speex not found using pkg-config
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig

# Openssl 1.1.* for SRS.
ADD openssl-1.1.1j.tar.bz2 /tmp
RUN cd /tmp/openssl-1.1.1j && \
   ./config -no-shared -no-threads --prefix=/usr/local/ssl && make -j${JOBS} && make install_sw

# Openssl 1.0.* for SRS.
#ADD openssl-OpenSSL_1_0_2u.tar.gz /tmp
#RUN cd /tmp/openssl-OpenSSL_1_0_2u && \
#    ./config -no-shared -no-threads --prefix=/usr/local/ssl && make -j${JOBS} && make install_sw

# Build latest cmake.
ADD CMake-3.22.5.tar.gz /tmp
# For linux/arm/v7, we install openssl-devel to build cmake.
# Otherwise, directly install cmake.
RUN  cd /tmp/CMake-3.22.5 && ./configure && make -j${JOBS} && make install
ENV PATH=$PATH:/usr/local/bin

# For FFMPEG
ADD nasm-2.14.tar.bz2 /tmp
RUN cd /tmp/nasm-2.14 && ./configure && make -j${JOBS} && make install
# For aac
ADD fdk-aac-0.1.3.tar.bz2 /tmp
RUN cd /tmp/fdk-aac-0.1.3 && bash autogen.sh && ./configure --disable-shared && make -j${JOBS} && make install
# For mp3
ADD lame-3.99.5.tar.bz2 /tmp
RUN cd /tmp/lame-3.99.5 && ./configure --disable-shared && make -j${JOBS} && make install
# For libspeex
ADD speex-1.2rc1.tar.bz2 /tmp
RUN cd /tmp/speex-1.2rc1 && ./configure --disable-shared && make -j${JOBS} && make install
# For libx264
ADD x264-snapshot-20181116-2245.tar.bz2 /tmp
RUN cd /tmp/x264-snapshot-20181116-2245 && ./configure --disable-shared --disable-cli --enable-static && make -j${JOBS} && make install
# The libsrt for SRS, which depends on openssl.
ADD srt-1.4.1.tar.gz /tmp
RUN cd /tmp/srt-1.4.1 && pwd && ls -lrhat && ./configure --disable-shared --enable-static --disable-app --disable-c++11 && make -j${JOBS} && make install
# For libxml2.
RUN apt install -y python-dev
ADD libxml2-2.9.12.tar.gz /tmp
RUN cd /tmp/libxml2-2.9.12 && ./autogen.sh && ./configure --disable-shared --enable-static && make -j${JOBS} && make install

# Build FFmpeg, static link libraries.
ADD ffmpeg-4.2.1.tar.bz2 /tmp
RUN cd /tmp/ffmpeg-4.2.1 && ./configure --enable-pthreads --extra-libs=-lpthread \
        --enable-gpl --enable-nonfree \
        --enable-postproc --enable-bzlib --enable-zlib \
        --enable-libx264 --enable-libmp3lame --enable-libfdk-aac \
        --enable-libxml2 --enable-demuxer=dash \
        --enable-libsrt --pkg-config-flags='--static' && \
	make -j${JOBS} && make install && echo "FFMPEG4 build and install successfully"
RUN cp /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg4

# For libx265. Note that we force to generate the x265.pc by replace X265_LATEST_TAG.
#     if(X265_LATEST_TAG)
#         configure_file("x265.pc.in" "x265.pc" @ONLY)
ADD x265-3.5_RC2.tar.bz2 /tmp
RUN cd /tmp/x265-3.5_RC2/build/linux && \
    sed -i 's/^if(X265_LATEST_TAG)/if(TRUE)/g' ../../source/CMakeLists.txt && \
    cmake -DENABLE_SHARED=OFF ../../source && make -j${JOBS} && make install

# Build FFmpeg, static link libraries.
ADD ffmpeg-5.0.2.tar.bz2 /tmp
RUN cd /tmp/ffmpeg-5.0.2 && ./configure --enable-pthreads --extra-libs=-lpthread \
        --pkg-config-flags='--static' \
        --enable-gpl --enable-nonfree \
        --enable-postproc --enable-bzlib --enable-zlib \
        --enable-libx264 --enable-libx265 --enable-libmp3lame --enable-libfdk-aac \
        --enable-libxml2 --enable-demuxer=dash \
        --enable-libsrt && \
    make -j${JOBS} && make install && echo "FFMPEG5 build and install successfully"
RUN cp /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg5

# Build FFmpeg, static link libraries.
ADD ffmpeg_rtmp_h265-5.0.tar.bz2 /tmp
RUN cp -f /tmp/ffmpeg_rtmp_h265-5.0/*.h /tmp/ffmpeg_rtmp_h265-5.0/*.c /tmp/ffmpeg-5.0.2/libavformat
RUN cd /tmp/ffmpeg-5.0.2 && ./configure --enable-pthreads --extra-libs=-lpthread \
        --pkg-config-flags='--static' \
        --enable-gpl --enable-nonfree \
        --enable-postproc --enable-bzlib --enable-zlib \
        --enable-libx264 --enable-libx265 --enable-libmp3lame --enable-libfdk-aac \
        --enable-libxml2 --enable-demuxer=dash \
        --enable-libsrt && \
    make -j${JOBS} && make install && echo "FFMPEG5(HEVC over RTMP) build and install successfully"
RUN cp /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg5-hevc-over-rtmp

#------------------------------------------------------------------------------------
#--------------------------dist------------------------------------------------------
#------------------------------------------------------------------------------------
# http://releases.ubuntu.com/xenial/
FROM ubuntu:xenial as dist

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
        autoconf automake libtool pkg-config liblzma-dev curl net-tools \
        tcl

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

# For cross-build: https://github.com/ossrs/srs/wiki/v4_EN_SrsLinuxArm#ubuntu-cross-build-srs
RUN apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Update the mirror from aliyun, @see https://segmentfault.com/a/1190000022619136
#ADD sources.list /etc/apt/sources.list
#RUN apt-get update

