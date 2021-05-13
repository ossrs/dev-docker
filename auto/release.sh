#!/usr/bin/env bash

git tag -d release-vsrt
git tag release-vsrt
git push origin -f release-vsrt
git push aliyun -f release-vsrt
