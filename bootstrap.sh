#!/bin/bash
swift-build-tool -f yaml-osx-llbuild.yaml
swift-build-tool -f llbuild-osx.yaml
cp .atllbuild/products/atbuild .