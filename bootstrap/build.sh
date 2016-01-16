#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd $SCRIPT_DIR

PLATFORM=macosx
BUILD_DIR=../.built
SWIFT_BUILD_TOOL=`which swift-build-tool`

if [ -n "$1" ]; then
  PLATFORM=$1
fi

if [ -z "$SWIFT_BUILD_TOOL" ]; then
  echo "The build tool 'swift-build-tool' cannot be found."
  exit 1
fi

if [ -d "$BUILD_DIR" ]; then 
  rm -rf "$BUILD_DIR"
fi

mkdir -p $BUILD_DIR/obj
mkdir -p $BUILD_DIR/tmp

$SWIFT_BUILD_TOOL -f bootstrap-$PLATFORM.swift-build --no-db

if [ "0" = "$?" ]; then
  rm -rf ../bin
  mkdir -p ../bin
  ln -s $BUILD_DIR/bootstrap/atbuild/atbuild ../bin/atbuild
fi