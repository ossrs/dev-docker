# SRS

![](http://ossrs.net:8000/gif/v1/sls.gif?site=github.com&path=/docker/v4)
[![](https://cloud.githubusercontent.com/assets/2777660/22814959/c51cbe72-ef92-11e6-81cc-32b657b285d5.png)](https://github.com/ossrs/srs/wiki/v1_CN_Contact#wechat)

The docker images for [SRS](https://github.com/ossrs/srs).

<a name="srs4"></a>
<a name="usage"></a>
## Usage

> SRS 4.0 is not released yet, so it's develop version and not stable.

Run SRS in docker by(images is [here](https://hub.docker.com/r/ossrs/srs/tags) or [there](https://cr.console.aliyun.com/repository/cn-hangzhou/ossrs/srs/images)):

```bash
docker run --rm -p 1935:1935 -p 1985:1985 -p 8080:8080 \
    ossrs/srs:v4.0.76
    
# Or, for developers in China to speedup.
docker run --rm -p 1935:1935 -p 1985:1985 -p 8080:8080 \
    registry.cn-hangzhou.aliyuncs.com/ossrs/srs:v4.0.76
    
# For macOS, with WebRTC
docker run --rm -p 1935:1935 -p 1985:1985 -p 8080:8080 \
    --env CANDIDATE=$(ifconfig en0 inet| grep 'inet '|awk '{print $2}') -p 8000:8000/udp \
    ossrs/srs:v4.0.76

# For CentOS, with WebRTC
docker run --rm -p 1935:1935 -p 1985:1985 -p 8080:8080 \
    --env CANDIDATE=$(ifconfig eth0|grep 'inet '|awk '{print $2}') -p 8000:8000/udp \
    ossrs/srs:v4.0.76
```

> For WebRTC, user MUST specify the ip by env `CANDIDATE`, please read [#307](https://github.com/ossrs/srs/issues/307).

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

> Note: If WebRTC enabled, you can publish by [H5](http://localhost:8080/players/rtc_publisher.html?autostart=true).

Play the following streams by players:

* VLC(RTMP): rtmp://localhost/live/livestream
* H5(HTTP-FLV): [http://localhost:8080/live/livestream.flv](http://localhost:8080/players/srs_player.html?autostart=true&stream=livestream.flv&port=8080&schema=http)
* H5(HLS): [http://localhost:8080/live/livestream.m3u8](http://localhost:8080/players/srs_player.html?autostart=true&stream=livestream.m3u8&port=8080&schema=http)
* H5(WebRTC): [webrtc://localhost/live/livestream](http://localhost:8080/players/rtc_player.html?autostart=true)

> The online demos and players are available on [ossrs.net](https://ossrs.net).

## Config

The config of docker is `/usr/local/srs/conf/srs.conf`, and logging to console.

To overwrite the config by `/path/of/yours.conf`:

```bash
docker run --rm -p 1935:1935 -p 1985:1985 -p 8080:8080 \
    -v /path/of/yours.conf:/usr/local/srs/conf/srs.conf \
    ossrs/srs:v4.0.76
```

> Note: How to config SRS, please read wiki([CN](https://github.com/ossrs/srs/wiki/v4_CN_Home)/[EN](https://github.com/ossrs/srs/wiki/v4_EN_Home)).

Winlin 2019.11
