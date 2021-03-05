#!/usr/bin/env bash

git tag -d release-vubuntu20
git tag release-vubuntu20
git push origin -f release-vubuntu20
git push aliyun -f release-vubuntu20
