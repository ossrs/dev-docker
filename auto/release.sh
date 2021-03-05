#!/usr/bin/env bash

git push origin && git push aliyun

git tag -d release-vdev6
git tag release-vdev6
git push origin -f release-vdev6
git push aliyun -f release-vdev6
