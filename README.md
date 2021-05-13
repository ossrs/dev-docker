# srs-docker

![](http://ossrs.net:8000/gif/v1/sls.gif?site=github.com&path=/docker/dev)
[![](https://cloud.githubusercontent.com/assets/2777660/22814959/c51cbe72-ef92-11e6-81cc-32b657b285d5.png)](https://github.com/ossrs/srs/wiki/v1_CN_Contact#wechat)

CentOS docker for [SRS](https://github.com/ossrs/srs) developer.

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
docker run -it --rm -v `pwd`:/srs -w /srs ossrs/srs:srt \
    bash -c "./configure --srt=on && make"
```

After build, the binary file `./objs/srs` is generated.

> Remark: Recomment to use [registry.cn-hangzhou.aliyuncs.com/ossrs/srs:srt](https://cr.console.aliyun.com/repository/cn-hangzhou/ossrs/srs/images) to speed-up.

**>>> Run SRS, read [#1147](https://github.com/ossrs/srs/issues/1147#issuecomment-577951899)**

Winlin, 2021.03
