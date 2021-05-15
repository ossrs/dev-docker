#!/usr/bin/env bash

git tag -d release-vubuntu18
git tag release-vubuntu18
git push origin -f release-vubuntu18
git push aliyun -f release-vubuntu18
