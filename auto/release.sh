#!/usr/bin/env bash

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
if [[ $MACOS == YES ]]; then
  sed -i '' "s|^ARG repo=.*$|ARG repo=ossrs/srs:dev|g" Dockerfile
else
  sed -i "s|^ARG repo=.*$|ARG repo=ossrs/srs:dev|g" Dockerfile
fi

git commit -am "Release encoder to docker hub"; git push
git tag -d release-vencoder
git tag release-vencoder
git push origin -f release-vencoder

# For aliyun hub.
if [[ $MACOS == YES ]]; then
  sed -i '' "s|^ARG repo=.*$|ARG repo=registry.cn-hangzhou.aliyuncs.com/ossrs/srs:dev|g" Dockerfile
else
  sed -i "s|^ARG repo=.*$|ARG repo=registry.cn-hangzhou.aliyuncs.com/ossrs/srs:dev|g" Dockerfile
fi

git commit -am "Release encoder to aliyun hub"; git push
git tag -d release-vencoder
git tag release-vencoder
git push aliyun -f release-vencoder
