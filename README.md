# SRS

![](http://ossrs.net:8000/gif/v1/sls.gif?site=github.com&path=/docker/encoder)
[![](https://cloud.githubusercontent.com/assets/2777660/22814959/c51cbe72-ef92-11e6-81cc-32b657b285d5.png)](https://github.com/ossrs/srs/wiki/v1_CN_Contact#wechat)

This is a encoder docker, to publish a RTMP stream to `rtmp://localhost/live/livestream`.

## Usage

Run encoder in docker by:

```bash
# For developer in China.
docker run --rm --network=host registry.cn-hangzhou.aliyuncs.com/ossrs/srs:encoder

# Or from docker hub.
docker run --rm --network=host ossrs/srs:encoder
```

It actually runs FFmpeg by:

```bash
docker run --rm --network=host registry.cn-hangzhou.aliyuncs.com/ossrs/srs:encoder \
  ffmpeg -re -i ./doc/source.200kbps.768x320.flv -c copy \
      -f flv -y rtmp://localhost/live/encoder
```

> Note: Use `--network=host` to publish to `localhost` which is another docker or SRS on host.

You can publish streams to any RTMP server, for example, `rtmp://r.ossrs.net/live/encoder`:

```bash
docker run --rm registry.cn-hangzhou.aliyuncs.com/ossrs/srs:encoder \
  ffmpeg -re -i ./doc/source.200kbps.768x320.flv -c copy \
      -f flv -y rtmp://r.ossrs.net/live/encoder
```

Winlin 2019.11
