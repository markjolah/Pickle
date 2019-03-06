
#!/bin/bash
# scripts/matlab-dist-build.sh <INSTALL_DIR> <cmake-args...>
#
# Builds a Matlab-only re-distributable release. A top-level startup@PACKAGE_NAME@.m will be created, which can be
# called in matlab to initialized all required Matlab code paths and dependencies.
#
# Args:
#  <cmake_args...> - additional cmake arguments.
#
# Optional environment variables:
#  INSTALL_PREFIX - path to distribution install prefix directory [Default: ${SRC_PATH}/_dist].
#                   The distribution files will be created under this directory with names based on
#                   package and versions.
#  OPT_DEBUG - Enable debugging builds
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_PATH=${SCRIPT_DIR}/..

NAME=$(grep -Po "project\(\K([A-Za-z]+)" ${SRC_PATH}/CMakeLists.txt)
VERSION=$(grep -Po "project\([A-Za-z]+ VERSION \K([0-9.]+)" ${SRC_PATH}/CMakeLists.txt)
if [ -z $NAME ] || [ -z $VERSION ]; then
    echo "Unable to find package name and version from: ${SRC_PATH}/CMakeLists.txt"
    exit 1
fi

DIST_DIR_NAME=${NAME}-${VERSION}
if [ -n "$INSTALL_PREFIX" ]; then
    INSTALL_PATH=$INSTALL_PREFIX/$DIST_DIR_NAME
else
    INSTALL_PATH=_matlab_dist/$DIST_DIR_NAME
fi

ZIP_FILE=${NAME}-${VERSION}.zip
TAR_FILE=${NAME}-${VERSION}.tbz2

BUILD_PATH=${SRC_PATH}/_build/dist
NUM_PROCS=$(grep -c ^processor /proc/cpuinfo)

ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DOPT_DOC=On"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=Off"
ARGS="${ARGS} -DOPT_MATLAB_INSTALL_DISTRIBUTION_STARTUP=On" #Copy startupPackage.m to root for distribution

set -ex
rm -rf $BUILD_PATH
rm -rf $INSTALL_PATH

cmake -H${SRC_PATH} -B$BUILD_PATH/Release -DCMAKE_BUILD_TYPE=Release ${ARGS} ${@:2}
#cmake --build $BUILD_PATH --target doc -- -j${NUM_PROCS}
#cmake --build $BUILD_PATH --target pdf -- -j${NUM_PROCS}
cmake --build $BUILD_PATH/Release --target install -- -j${NUM_PROCS}

cd $INSTALL_PATH/..
zip -rq $ZIP_FILE $DIST_DIR_NAME
tar cjf $TAR_FILE $DIST_DIR_NAME
