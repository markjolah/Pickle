#!/bin/bash
# build.sh <cmake-args...>
#
# Pickle matlab-only default build script.
#
# Clean release-only build to local install prefix with build-tree export support.
# Cleans up build and install directories.  For safety, deletes the install dir
# if and only if INSTALL_PATH hasn't been modified from the default "_install"

INSTALL_PATH=_install
BUILD_PATH=_build/Release
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`

ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DOPT_DOC=Off"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=On"

set -ex

if [ "$INSTALL_PATH" == "_install" ]; then
    rm -rf _install
fi

rm -rf $BUILD_PATH
cmake -H. -B$BUILD_PATH -DCMAKE_BUILD_TYPE=Release ${ARGS}
cmake --build $BUILD_PATH --target install -- -j${NUM_PROCS}
