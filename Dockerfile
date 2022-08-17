FROM node:16-buster

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y git

RUN mkdir -p /usr/local/srs-docs-cache
RUN cd /usr/local/srs-docs-cache && git clone --depth=1 https://github.com/ossrs/srs-docs.git
RUN cd /usr/local/srs-docs-cache/srs-docs && yarn && yarn build
RUN cd /usr/local/srs-docs-cache && du -sh *

