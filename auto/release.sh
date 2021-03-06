#!/bin/bash

echo "Push code"
git push && git push aliyun

OS=`python -mplatform 2>&1`
MACOS=NO && CENTOS=NO && UBUNTU=NO && CENTOS7=NO
echo $OS|grep -i "darwin" >/dev/null && MACOS=YES
echo $OS|grep -i "centos" >/dev/null && CENTOS=YES
echo $OS|grep -i "redhat" >/dev/null && CENTOS=YES
echo $OS|grep -i "ubuntu" >/dev/null && UBUNTU=YES
if [[ $CENTOS == YES ]]; then
    lsb_release -r|grep "7\." >/dev/null && CENTOS7=YES
fi
echo "OS is $OS(Darwin:$MACOS, CentOS:$CENTOS, Ubuntu:$UBUNTU) (CentOS7:$CENTOS7)"

# For docker hub.
SRS_TAG=release-vstudy
NICE "docker hub $SRS_TAG"
echo ""

SRS_GITHUB=https://github.com/ossrs/srs.git
if [[ $MACOS == YES ]]; then
  sed -i '' "s|^ARG url=.*$|ARG url=${SRS_GITHUB}|g" Dockerfile
  sed -i '' "s|^ARG repo=.*$|ARG repo=ossrs/srs:dev|g" Dockerfile
else
  sed -i "s|^ARG url=.*$|ARG url=${SRS_GITHUB}|g" Dockerfile
  sed -i "s|^ARG repo=.*$|ARG repo=ossrs/srs:dev|g" Dockerfile
fi

git commit -am "Release $SRS_TAG to docker hub"; git push
echo "Commit changes of tag $SRS_TAG for docker"

git tag -d $SRS_TAG 2>/dev/null
echo "Cleanup tag $SRS_TAG for docker"

git tag $SRS_TAG; git push origin -f $SRS_TAG
echo "Create new tag $SRS_TAG for docker"
echo ""

# For aliyun hub.
NICE "aliyun hub $SRS_TAG"

SRS_GITEE=https://gitee.com/winlinvip/srs.oschina.git
if [[ $MACOS == YES ]]; then
  sed -i '' "s|^ARG url=.*$|ARG url=${SRS_GITEE}|g" Dockerfile
  sed -i '' "s|^ARG repo=.*$|ARG repo=registry.cn-hangzhou.aliyuncs.com/ossrs/srs:dev|g" Dockerfile
else
  sed -i "s|^ARG url=.*$|ARG url=${SRS_GITEE}|g" Dockerfile
  sed -i "s|^ARG repo=.*$|ARG repo=registry.cn-hangzhou.aliyuncs.com/ossrs/srs:dev|g" Dockerfile
fi

git commit -am "Release $SRS_TAG to docker hub"; git push
echo "Commit changes of tag $SRS_TAG for aliyun"

git tag -d $SRS_TAG 2>/dev/null
echo "Cleanup tag $SRS_TAG for aliyun"

git tag $SRS_TAG; git push -f aliyun $SRS_TAG
echo "Create new tag $SRS_TAG for aliyun"
echo ""

