
############################################################
# build
############################################################
ARG repo=registry.cn-hangzhou.aliyuncs.com/ossrs/srs:dev
FROM ${repo} AS build
COPY doc /usr/local/srs/doc

############################################################
# dist
############################################################
FROM centos:7 AS dist
# FFMPEG 4.1
COPY --from=build /usr/local/bin/ffmpeg /usr/local/srs/objs/ffmpeg/bin/ffmpeg
COPY --from=build /usr/local/ssl /usr/local/ssl
# For libsrt
COPY --from=build /usr/local/include/srt /usr/local/include/srt
COPY --from=build /usr/local/lib64 /usr/local/lib64
# FLV demo file.
COPY --from=build /usr/local/srs/doc /usr/local/srs/doc
# Default workdir and command.
WORKDIR /usr/local/srs
ENV PATH $PATH:/usr/local/srs/objs/ffmpeg/bin
# Set the ENV by --env CANDIDATE=localhost as such.
ENV SOURCE=doc/source.200kbps.768x320.flv
ENV URL=rtmp://127.0.0.1/live/livestream
CMD ["bash", "-c", "ffmpeg -re -i $SOURCE -c copy -f flv -y $URL"]
