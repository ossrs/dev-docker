#!/usr/bin/env bash

git tag -d release-vubuntu16
git tag release-vubuntu16
git push origin -f release-vubuntu16
git push aliyun -f release-vubuntu16
