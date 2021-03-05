# https://docs.docker.com/engine/reference/builder/#arg
# @remark Please never modify it, the auto/release.sh will update it automatically.
ARG tag=v4.0.14
ARG url=https://gitee.com/winlinvip/srs.oschina.git

############################################################
# build
############################################################
ARG repo=registry.cn-hangzhou.aliyuncs.com/ossrs/srs:dev
FROM ${repo} AS build
ARG tag
ARG url
# Install required tools.
RUN yum install -y gcc make gcc-c++ patch unzip perl git
RUN cd /tmp && git clone --depth=1 --branch ${tag} ${url} srs
RUN cd /tmp/srs/trunk && ./configure && make && make install
# All config files for SRS.
COPY conf /usr/local/srs/conf
# The default index.html and srs-console.
COPY index.html /usr/local/srs/objs/nginx/html/index.html
COPY favicon.ico /usr/local/srs/objs/nginx/html/favicon.ico
COPY srs-console/trunk/research/console /usr/local/srs/objs/nginx/html/console
COPY srs.release/trunk/research/players /usr/local/srs/objs/nginx/html/players

############################################################
# dist
############################################################
FROM centos:7 AS dist
# RTMP/1935, API/1985, HTTP/8080
EXPOSE 1935 1985 8080
# FFMPEG 4.1
COPY --from=build /usr/local/bin/ffmpeg /usr/local/srs/objs/ffmpeg/bin/ffmpeg
# SRS binary, config files and srs-console.
COPY --from=build /usr/local/srs /usr/local/srs
# Use docker.conf as default config.
COPY conf/docker.conf /usr/local/srs/conf/srs.conf
# Default workdir and command.
WORKDIR /usr/local/srs
CMD ["./objs/srs", "-c", "conf/srs.conf"]
