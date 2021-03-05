#!/usr/bin/env bash

git push origin && git push aliyun

git tag -d release-vdev8
git tag release-vdev8
git push origin -f release-vdev8
git push aliyun -f release-vdev8

