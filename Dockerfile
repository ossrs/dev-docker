
############################################################
# build
############################################################
ARG ARCH
FROM ${ARCH}ossrs/srs:ubuntu20 AS build

############################################################
# dist
############################################################
FROM ${ARCH}node:slim as dist

ARG BUILDPLATFORM
ARG TARGETPLATFORM
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM"

# Copy all binaries.
COPY --from=build /usr/local/bin/ffmpeg4 /usr/local/bin/ffprobe4 /usr/local/bin/
COPY --from=build /usr/local/bin/ffmpeg5 /usr/local/bin/ffprobe5 /usr/local/bin/
RUN rm -f /usr/local/bin/ffmpeg && ln -sf /usr/local/bin/ffmpeg5 /usr/local/bin/ffmpeg
RUN rm -f /usr/local/bin/ffprobe && ln -sf /usr/local/bin/ffprobe5 /usr/local/bin/ffprobe

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND noninteractive

# Install depends for FFmpeg.
RUN apt-get update && apt-get install -y libxml2-dev

