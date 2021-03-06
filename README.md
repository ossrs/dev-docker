# SRS

![](http://ossrs.net:8000/gif/v1/sls.gif?site=github.com&path=/docker/study)
[![](https://cloud.githubusercontent.com/assets/2777660/22814959/c51cbe72-ef92-11e6-81cc-32b657b285d5.png)](https://github.com/ossrs/srs/wiki/v1_CN_Contact#wechat)

这是一个学习[SRS](https://github.com/ossrs/srs)的Docker镜像。

## Usage

从[这里](https://www.docker.com/products/docker-desktop)下载Docker，然后安装。

获取`ossrs/srs:study`镜像：

```bash
docker run --rm ossrs/srs:study

# Or, for developers in China to speedup.
docker run --rm registry.cn-hangzhou.aliyuncs.com/ossrs/srs:study
```

Docker内部包含了调试环境和SRS的代码:

```bash
/srs/trunk
    +- 3rdparty # 第三方依赖库，比如ST、SRTP、FFmpeg、OpenSSL等
    +- conf # 配置文件，不同场景的配置文件
    +- gdb # SRS特别的一些GDB脚本
    +- research # 一些调研和学习的代码，播放器也在这里
    +- src # SRS的代码的目录
    +- objs # 编译的结果
```

Winlin 2021.03
