# srs-docker

![](http://ossrs.net:8000/gif/v1/sls.gif?site=github.com&path=/docker/dev)
[![](https://cloud.githubusercontent.com/assets/2777660/22814959/c51cbe72-ef92-11e6-81cc-32b657b285d5.png)](https://github.com/ossrs/srs/wiki/v1_CN_Contact#wechat)
[![](https://github.com/ossrs/developer/actions/workflows/release.yml/badge.svg?branch=dev)](https://github.com/ossrs/developer/actions/workflows/release.yml?query=workflow%3ARelease+branch%3Adev)

The dev(CentOS7) docker for [SRS](https://github.com/ossrs/srs) developer.

## Usage

**>>> Install docker**

Download docker from [here](https://www.docker.com/products/docker-desktop) then start docker.

**>>> Clone SRS**

```
cd ~/git &&
git clone https://gitee.com/ossrs/srs.git srs && cd srs/trunk && 
git remote set-url origin https://github.com/ossrs/srs.git && git pull
```

> Note: Please read https://github.com/ossrs/srs#usage

**>>> Build SRS in dev docker**

```
cd ~/git/srs/trunk &&
docker run -it --rm -v `pwd`:/srs -w /srs ossrs/srs:dev \
    bash -c "./configure && make"
```

After build, the binary file `./objs/srs` is generated.

> Remark: Recomment to use [registry.cn-hangzhou.aliyuncs.com/ossrs/srs:dev](https://cr.console.aliyun.com/repository/cn-hangzhou/ossrs/srs/images) to speed-up.

**Run SRS in dev docker**

```
cd ~/git/srs/trunk &&
docker run -p 1935:1935 -p 1985:1985 -p 8080:8080 -p 8085:8085 \
     -it --rm -v `pwd`:/srs -w /srs ossrs/srs:dev \
    ./objs/srs -c conf/console.conf

# Or for macOS, with WebRTC.
docker run -p 1935:1935 -p 1985:1985 -p 8080:8080 -p 8085:8085 \
    --env CANDIDATE=$(ifconfig en0 inet| grep 'inet '|awk '{print $2}') -p 8000:8000/udp \
     -it --rm -v `pwd`:/srs -w /srs ossrs/srs:dev \
    ./objs/srs -c conf/console.conf
```

> For WebRTC, user MUST specify the ip by env `CANDIDATE`, please read [Config: Candidate](https://github.com/ossrs/srs/wiki/v4_CN_WebRTC#config-candidate).

**Debug SRS by GDB in dev docker**

```
cd ~/git/srs/trunk &&
docker run -p 1935:1935 -p 1985:1985 -p 8080:8080 -p 8085:8085 \
    --env CANDIDATE=$(ifconfig en0 inet| grep 'inet '|awk '{print $2}') -p 8000:8000/udp \
    --privileged -it --rm -v `pwd`:/srs -w /srs ossrs/srs:dev \
    gdb --args ./objs/srs -c conf/console.conf
```

## GDB

To run docker with `--privileged` for GDB, or it fail for error `Cannot create process: Operation not permitted`.

Winlin, 2021.03
