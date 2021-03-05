# SRS

![](http://ossrs.net:8000/gif/v1/sls.gif?site=github.com&path=/docker/v2)
[![](https://cloud.githubusercontent.com/assets/2777660/22814959/c51cbe72-ef92-11e6-81cc-32b657b285d5.png)](https://github.com/ossrs/srs/wiki/v1_CN_Contact#wechat)

The docker images for [SRS](https://github.com/ossrs/srs).

<a name="srs2"></a>
<a name="usage"></a>
## Usage

By default, `ossrs/srs:2` is the latest [SRS2](https://github.com/ossrs/srs/tree/2.0release) image, 
others is [here](https://github.com/ossrs/srs/tags) such as [ossrs/srs:v2.0-r8](https://github.com/ossrs/srs/releases/tag/v2.0-r8).

Run SRS in docker by:

```bash
docker run --rm -p 1935:1935 -p 1985:1985 -p 8080:8080 ossrs/srs:2

# Or, for developers in China to speedup.
docker run --rm -p 1935:1935 -p 1985:1985 -p 8080:8080 \
    registry.cn-hangzhou.aliyuncs.com/ossrs/srs:2
```

If it works, open [http://localhost:8080/](http://localhost:8080/) to check it, then publish
[stream](https://github.com/ossrs/srs/blob/3.0release/trunk/doc/source.200kbps.768x320.flv) by:

```bash
ffmpeg -re -i doc/source.200kbps.768x320.flv -c copy \
    -f flv rtmp://localhost/live/livestream

# Or by FFmpeg docker
docker run --rm --network=host registry.cn-hangzhou.aliyuncs.com/ossrs/srs:encoder \
  ffmpeg -re -i ./doc/source.200kbps.768x320.flv -c copy \
      -f flv -y rtmp://localhost/live/livestream
```

Play the following streams by players:

* VLC(RTMP): rtmp://localhost/live/livestream
* H5(HTTP-FLV): [http://localhost:8080/live/livestream.flv](http://localhost:8080/players/srs_player.html?autostart=true&stream=livestream.flv&port=8080&schema=http)
* H5(HLS): [http://localhost:8080/live/livestream.m3u8](http://localhost:8080/players/srs_player.html?autostart=true&stream=livestream.m3u8&port=8080&schema=http)

> The online demos and players are available on [ossrs.net](https://ossrs.net).

## Config

The config of docker is `/usr/local/srs/conf/srs.conf`, and logging to console.

To overwrite the config by `/path/of/yours.conf`:

```bash
docker run --rm -p 1935:1935 -p 1985:1985 -p 8080:8080 \
    -v /path/of/yours.conf:/usr/local/srs/conf/srs.conf \
    ossrs/srs:2
```

> Note: How to config SRS, please read wiki([CN](https://github.com/ossrs/srs/wiki/v2_CN_Home)/[EN](https://github.com/ossrs/srs/wiki/v2_EN_Home)).

Winlin 2019.11
