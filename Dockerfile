
############################################################
# build
############################################################
ARG repo=ossrs/srs:dev
FROM ${repo} AS build
COPY doc /usr/local/srs/doc

############################################################
# dist
############################################################
FROM centos:7 AS dist

# FFmpeg.
COPY --from=build /usr/local/bin/ffmpeg4 /usr/local/bin/ffmpeg4
COPY --from=build /usr/local/bin/ffmpeg5 /usr/local/bin/ffmpeg5
COPY --from=build /usr/local/bin/ffmpeg5-hevc-over-rtmp /usr/local/bin/ffmpeg5-hevc-over-rtmp
RUN ln -sf /usr/local/bin/ffmpeg5-hevc-over-rtmp /usr/local/bin/ffmpeg
COPY --from=build /usr/local/bin/ffprobe /usr/local/bin/ffprobe
# OpenSSL.
COPY --from=build /usr/local/ssl /usr/local/ssl
# For libsrt
#COPY --from=build /usr/local/include/srt /usr/local/include/srt
#COPY --from=build /usr/local/lib64 /usr/local/lib64
# FLV demo file.
COPY --from=build /usr/local/srs/doc /usr/local/srs/doc

# Default workdir and command.
WORKDIR /usr/local/srs
ENV PATH=$PATH:/usr/local/srs/objs/ffmpeg/bin

# Set the ENV by --env CANDIDATE=localhost as such.
ENV FFMPEG=ffmpeg
ENV FFMPEG_PRE="-re -i"
ENV SOURCE=doc/source.200kbps.768x320.flv
ENV FFMPEG_POST="-c copy -f flv"
ENV URL=rtmp://127.0.0.1/live/livestream
CMD ["bash", "-c", "$FFMPEG $FFMPEG_PRE $SOURCE $FFMPEG_POST $URL"]

