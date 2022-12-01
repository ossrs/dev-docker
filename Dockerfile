
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

# Note that we can't do condional copy, because cmake has bin, docs and share files, so we copy the whole /usr/local
# directory or cmake will fail.
COPY --from=build /usr/local /usr/local
# Note that for armv7, the ffmpeg5-hevc-over-rtmp is actually ffmpeg5.
RUN ln -sf /usr/local/bin/ffmpeg5-hevc-over-rtmp /usr/local/bin/ffmpeg
# Note that the PATH has /usr/local/bin by default in ubuntu:focal.
#ENV PATH=$PATH:/usr/local/bin

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

