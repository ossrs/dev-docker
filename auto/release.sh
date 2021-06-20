#!/usr/bin/env bash

git tag -d release-vaarch64
git tag release-vaarch64
git push origin -f release-vaarch64
git push aliyun -f release-vaarch64
