#!/bin/bash

SRS_FILTER=`git branch|grep \*|awk '{print $2}'`
SRS_GIT=$HOME/git/srs
SRS_TAG=
SRS_MAJOR=
CHECK_BRANCH=YES

# linux shell color support.
RED="\\033[31m"
GREEN="\\033[32m"
YELLOW="\\033[33m"
BLACK="\\033[0m"

function NICE() {
    echo -e "${GREEN}$@${BLACK}"
}

function TRACE() {
    echo -e "${BLACK}$@${BLACK}"
}

function WARN() {
    echo -e "${YELLOW}$@${BLACK}"
}

function ERROR() {
    echo -e "${RED}$@${BLACK}"
}

##################################################################################
##################################################################################
##################################################################################
# parse options.
for option
do
    case "$option" in
        -*=*)
            value=`echo "$option" | sed -e 's|[-_a-zA-Z0-9/]*=||'`
            option=`echo "$option" | sed -e 's|=[-_a-zA-Z0-9/.]*||'`
        ;;
           *) value="" ;;
    esac

    case "$option" in
        -h)                             help=yes                  ;;
        --help)                         help=yes                  ;;

        -v2)                            SRS_FILTER=v2             ;;
        --v2)                           SRS_FILTER=v2             ;;
        -v3)                            SRS_FILTER=v3             ;;
        --v3)                           SRS_FILTER=v3             ;;
        -v4)                            SRS_FILTER=v4             ;;
        --v4)                           SRS_FILTER=v4             ;;
        --git)                          SRS_GIT=$value            ;;
        --tag)                          SRS_TAG=$value            ;;
        --any-branch)                   CHECK_BRANCH=NO           ;;

        *)
            echo "$0: error: invalid option \"$option\", @see $0 --help"
            exit 1
        ;;
    esac
done

if [[ -z $SRS_FILTER ]]; then
  echo "No branch"
  help=yes
fi

if [[ $SRS_FILTER != v2 && $SRS_FILTER != v3 && $SRS_FILTER != v4 ]]; then
  echo "Invalid filter $SRS_FILTER"
  help=yes
fi

if [[ ! -d $SRS_GIT ]]; then
  echo "No directory $SRS_GIT"
  help=yes
fi

if [[ $help == yes ]]; then
    cat << END

  -h, --help    Print this message

  -v2, --v2     Package the latest tag of 2.0release branch, such as v2.0-r7.
  -v3, --v3     Package the latest tag of 3.0release branch, such as v3.0-a2.
  -v4, --v4     Package the latest tag of 4.0release branch, such as v4.0.23.
  --git         The SRS git source directory to fetch the latest tag. Default: $HOME/git/srs
  --tag         The tag to build the docker. Retrieve from branch.
  --any-branch  Don't check branch, allow any branch to create tag.
END
    exit 0
fi

if [[ $CHECK_BRANCH == YES ]]; then
  SRS_BRANCH=`(cd $SRS_GIT && git branch|grep \*|awk '{print $2}')`
  if [[ $? -ne 0 ]]; then
    echo "Invalid branch in $SRS_GIT"
    exit -1
  fi

  if [[ "v${SRS_BRANCH}" != "${SRS_FILTER}.0release" ]]; then
    echo "Invalid branch $SRS_BRANCH in $SRS_GIT for release $SRS_FILTER"
    exit -1
  fi
fi

if [[ -z $SRS_TAG ]]; then
  SRS_TAG=`(cd $SRS_GIT && git describe --tags --abbrev=0 --match ${SRS_FILTER}.0* 2>/dev/null)`
  if [[ $? -ne 0 ]]; then
    echo "Invalid tag $SRS_TAG of $SRS_FILTER in $SRS_GIT"
    exit -1
  fi
fi

SRS_MAJOR=`echo $SRS_TAG|sed 's/^v//g'|awk -F '.' '{print $1}' 2>&1`
if [[ $? -ne 0 ]]; then
  echo "Invalid major version $SRS_MAJOR"
  exit -1
fi

# If v3.0-b0, it's not temporary release.
# If v3.0.125, it's temporary release. We won't update srs:3 and srs:latest.
TEMPORARY_RELEASE=YES;
echo $SRS_TAG| grep -q '-' && TEMPORARY_RELEASE=NO;

NICE "Build docker for fitler=$SRS_FILTER of $SRS_GIT, tag is $SRS_TAG, major=$SRS_MAJOR, temp=$TEMPORARY_RELEASE"

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

if [[ $MACOS == YES ]]; then
  sed -i '' "s|^ARG tag=.*$|ARG tag=${SRS_TAG}|g" Dockerfile
else
  sed -i "s|^ARG tag=.*$|ARG tag=${SRS_TAG}|g" Dockerfile
fi

# For docker hub.
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
NICE "aliyun hub release-v$SRS_TAG"

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

git tag -d release-v$SRS_TAG 2>/dev/null
echo "Cleanup tag $SRS_TAG for aliyun"

git tag release-v$SRS_TAG; git push -f aliyun release-v$SRS_TAG
echo "Create new tag $SRS_TAG for aliyun"
echo ""

# For temporary release, we don't update srs:3 or srs:latest
if [[ $TEMPORARY_RELEASE == YES ]]; then
  exit 0;
fi

NICE "aliyun hub release-v$SRS_MAJOR"

git tag -d release-v$SRS_MAJOR 2>/dev/null
echo "Cleanup tag $SRS_MAJOR for aliyun"

git tag release-v$SRS_MAJOR; git push -f aliyun release-v$SRS_MAJOR
echo "Create new tag $SRS_MAJOR for aliyun"
echo ""

if [[ $SRS_MAJOR == 3 ]]; then
  NICE "aliyun hub release-vlatest"
  git tag -d release-vlatest 2>/dev/null
  echo "Cleanup tag latest for aliyun"

  git tag release-vlatest; git push -f aliyun release-vlatest
  echo "Create new tag latest for aliyun"
fi

