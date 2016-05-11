#!/bin/bash
set -e
UNAME=`uname`


echo "**********THE ATBUILD TEST SCRIPT*************"

DIR=`pwd`
ATBUILD="`pwd`/.atllbuild/products/atbuild"
pwd

echo "****************SELF-HOSTING TEST**************"
export ATBUILD_PACKAGE_VERSION="1.2"
echo "Remove this line after releasing 1.2"

if [ "$UNAME" == "Darwin" ]; then
    PLATFORM_SPECIFIC_PACKAGE="package-osx"
else
    PLATFORM_SPECIFIC_PACKAGE="package-linux"
fi

if ! $ATBUILD $PLATFORM_SPECIFIC_PACKAGE --use-overlay static; then
    echo "Self-host failed; maybe you're not running CaffeinatedSwift?"
    echo "Retrying with non-static build"
    $ATBUILD $PLATFORM_SPECIFIC_PACKAGE
fi

echo "****************ONLY-PLATFORMS TEST**************"
cd $DIR/tests/fixtures/only_platforms
$ATBUILD > /tmp/only.txt

if [ "$UNAME" == "Darwin" ]; then
    EXPECT="hello from osx"
    DONTEXPECT="hello from linux"
else
    EXPECT="hello from linux"
    DONTEXPECT="hello from osx"
fi
if ! grep "$EXPECT" /tmp/only.txt; then
    echo "Didn't find $EXPECT in /tmp/only.txt"
    exit 1
fi

if grep "$DONTEXPECT" /tmp/only.txt; then
    echo "Found $DONTEXPECT in /tmp/only.txt"
    exit 1
fi


echo "****************EXECUTABLE-NAME TEST**************"
cd $DIR/tests/fixtures/executable_name
$ATBUILD check

echo "****************ATBIN TEST**************"
cd $DIR/tests/fixtures/atbin

$ATBUILD
#did we build all the things we were supposed to?

if [ "$UNAME" == "Darwin" ]; then
    if [ ! -f "bin/dynamicatbin.atbin/osx.swiftmodule" ]; then
        echo "Missing swiftmodule"
        exit 1
    fi
    if [ ! -f "bin/dynamicatbin.atbin/osx.swiftdoc" ]; then
        echo "Missing swiftdoc"
        exit 1
    fi

    if [ ! -f "bin/dynamicatbin.atbin/dlib.dylib" ]; then
        echo "Missing dylib"
        exit 1
    fi

    if [ ! -f "bin/staticatbin.atbin/osx.swiftmodule" ]; then
        echo "Missing swiftmodule"
        exit 1
    fi
    if [ ! -f "bin/staticatbin.atbin/osx.swiftdoc" ]; then
        echo "Missing swiftdoc"
        exit 1
    fi

    if [ ! -f "bin/dynamicatbin-1.0-osx.atbin.tar.xz" ]; then
        echo "Missing compressed atbin"
        exit 1
    fi
    tar xf bin/dynamicatbin-1.0-osx.atbin.tar.xz
else
    if [ ! -f "bin/dynamicatbin.atbin/linux.swiftmodule" ]; then
        echo "Missing swiftmodule"
        exit 1
    fi
    if [ ! -f "bin/dynamicatbin.atbin/linux.swiftdoc" ]; then
        echo "Missing swiftdoc"
        exit 1
    fi

    if [ ! -f "bin/dynamicatbin.atbin/dlib.so" ]; then
        echo "Missing dylib"
        exit 1
    fi

    if [ ! -f "bin/staticatbin.atbin/linux.swiftmodule" ]; then
        echo "Missing swiftmodule"
        exit 1
    fi
    if [ ! -f "bin/staticatbin.atbin/linux.swiftdoc" ]; then
        echo "Missing swiftdoc"
        exit 1
    fi

    if [ ! -f "bin/dynamicatbin-1.0-linux.atbin.tar.xz" ]; then
        echo "Missing compressed atbin"
        exit 1
    fi
    tar xf bin/dynamicatbin-1.0-linux.atbin.tar.xz
fi

# check non-platform-specific-things
if [ ! -f "bin/staticatbin.atbin/module.modulemap" ]; then
    echo "Missing modulemap"
    exit 1
fi
if [ ! -f "bin/dynamicatbin.atbin/module.modulemap" ]; then
    echo "Missing modulemap"
    exit 1
fi

if [ ! -f "bin/staticatbin.atbin/compiled.atpkg" ]; then
    echo "Missing compiled.atpkg"
    exit 1
fi
if [ ! -f "bin/dynamicatbin.atbin/compiled.atpkg" ]; then
    echo "Missing compiled.atpkg"
    exit 1
fi

if [ ! -f "bin/executableatbin.atbin/compiled.atpkg" ]; then
    echo "Missing compiled.atpkg"
    exit 1
fi

if [ ! -f "bin/executableatbin.atbin/exec" ]; then
    echo "Missing payload"
    exit 1
fi

if [ ! -f "bin/staticatbin.atbin/slib.a" ]; then
    echo "Missing payload"
    exit 1
fi


if [ "$UNAME" == "Darwin" ]; then
    $ATBUILD --platform ios

    #check archs
    FILE=`file bin/staticatbin.atbin/slib.a | wc -l | bc`
    if [ "$FILE" != "5" ]; then
        echo "Architecture mismatch (static iOS) $FILE"
        exit 1
    fi 

    FILE=`file bin/executableatbin.atbin/exec | wc -l | bc`
    if [ "$FILE" != "5" ]; then
        echo "Architecture mismatch (executable iOS) $FILE"
        exit 1
    fi 

    FILE=`file bin/dynamicatbin.atbin/dlib.dylib | wc -l | bc`
    if [ "$FILE" != "5" ]; then
        echo "Architecture mismatch (dynamic library iOS) $FILE"
        exit 1
    fi 

    FILE=`file bin/sim.atbin/slib.a | wc -l | bc`
    if [ "$FILE" != "3" ]; then
        echo "Architecture mismatch (sim iOS) $FILE"
        exit 1
    fi 

fi


echo "****************USAGE TEST**************"
cd $DIR/tests/fixtures/nonstandard_package_file
$ATBUILD --help > /tmp/usage.txt || true
if ! grep "Usage:" /tmp/usage.txt; then
    echo "Didn't print usage"
    exit 1
fi


echo "****************PLUGIN TEST**************"
cd $DIR/tests/fixtures/attool
$ATBUILD > /tmp/plugin.txt
if [ "$UNAME" == "Darwin" ]; then
    SEARCHTEXT="\-bindir .*tests/fixtures/attool/bin --key value --platform osx --test test_substitution --userpath .*tests/fixtures/attool/user --version 1.0"
else
    SEARCHTEXT="\-bindir .*tests/fixtures/attool/bin --key value --platform linux --test test_substitution --userpath .*tests/fixtures/attool/user --version 1.0"
fi

if ! grep "$SEARCHTEXT" /tmp/plugin.txt; then
    cat /tmp/plugin.txt
    echo "Did not find key print in plugin test"
    echo $SEARCHTEXT
    exit 1
fi

echo "****************IOS TEST**************"
cd $DIR/tests/fixtures/ios
if [ "$UNAME" == "Darwin" ]; then
    $ATBUILD --platform ios-x86_64 ##FIXME
    INFO=`lipo -info .atllbuild/products/static.a`
    if [[ "$INFO" != *"architecture: x86_64"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi
    INFO=`lipo -info .atllbuild/products/dynamic.dylib`
    if [[ "$INFO" != *"architecture: x86_64"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi

    INFO=`lipo -info .atllbuild/products/executable`
    if [[ "$INFO" != *"architecture: x86_64"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi


    $ATBUILD --platform ios-i386
    INFO=`lipo -info .atllbuild/products/static.a`
    if [[ "$INFO" != *"architecture: i386"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi
    INFO=`lipo -info .atllbuild/products/dynamic.dylib`
    if [[ "$INFO" != *"architecture: i386"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi

    INFO=`lipo -info .atllbuild/products/executable`
    if [[ "$INFO" != *"architecture: i386"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi

    $ATBUILD --platform ios-arm64
    INFO=`lipo -info .atllbuild/products/static.a`
    if [[ "$INFO" != *"architecture: arm64"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi
    INFO=`lipo -info .atllbuild/products/dynamic.dylib`
    if [[ "$INFO" != *"architecture: arm64"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi

    INFO=`lipo -info .atllbuild/products/executable`
    if [[ "$INFO" != *"architecture: arm64"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi

    $ATBUILD --platform ios-armv7
    INFO=`lipo -info .atllbuild/products/static.a`
    if [[ "$INFO" != *"architecture: armv7"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi
    INFO=`lipo -info .atllbuild/products/dynamic.dylib`
    if [[ "$INFO" != *"architecture: armv7"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi

    INFO=`lipo -info .atllbuild/products/executable`
    if [[ "$INFO" != *"architecture: armv7"* ]]; then
        echo "bad architecture $INFO"
        exit 1
    fi

else
    echo "Skipping iOS tests on non-Darwin platform"
fi

echo "****************PLATFORMS TEST**************"
cd $DIR/tests/fixtures/platforms
UNAME=`uname`
$ATBUILD check 2&> /tmp/platforms.txt
if [ "$UNAME" == "Darwin" ]; then
    STR="Hello from OSX!"
else
    STR="Hello from LINUX!"
fi
if ! grep "$STR" /tmp/platforms.txt; then
    cat /tmp/platforms.txt
    echo "Did not find platform print in platform test"
    exit 1
fi

#check bootstrapping case
$ATBUILD build --use-overlay bootstrap-only --platform linux
if ! cmp --silent bin/bootstrap-platform.yaml known-linux-bootstrap.yaml; then
    echo "Linux bootstrap was unexpected"
    exit 1
fi

$ATBUILD build --use-overlay bootstrap-only --platform osx
if ! cmp --silent bin/bootstrap-platform.yaml known-osx-bootstrap.yaml; then
    echo "OSX bootstrap was unexpected"
    exit 1
fi



echo "****************XCODE TOOLCHAIN TEST**************"

if [ -e "/Applications/Xcode.app" ]; then
    cd $DIR/tests/fixtures/xcode_toolchain
    $ATBUILD --toolchain xcode
else
    echo "Xcode is not installed; skipping test"
fi

echo "****************PACKAGE FRAMEWORK TESTS**************"
UNAME=`uname`
if [ "$UNAME" == "Darwin" ]; then
    cd $DIR/tests/fixtures/package_framework
    $ATBUILD check
else
    echo "Skipping framework tests on this platform"
fi
echo "****************COLLECT SOURCES TEST**************"
cd $DIR/tests/fixtures/collect_sources
$ATBUILD collect-sources 2&> /tmp/sources.txt
if ! grep "sources src/a.swift src/b.swift" /tmp/sources.txt; then
    if ! grep "sources src/b.swift src/a.swift" /tmp/sources.txt; then
        exit 1
    fi
fi

echo "****************DYNAMIC LIBRARY TEST**************"
cd $DIR/tests/fixtures/dynamic_library
$ATBUILD
.atllbuild/products/dynamic_library_tester

echo "****************WMO TEST**************"
cd $DIR/tests/fixtures/wmo
$ATBUILD

echo "****************UMBRELLA TEST**************"
cd $DIR/tests/fixtures/umbrella_header
$ATBUILD check

echo "****************USER PATH TEST**************"
cd $DIR/tests/fixtures/user_paths

$ATBUILD third
RESULT=`cat user/test`
RESULT2="FIRST
SECOND
THIRD"
if [ "$RESULT" != "$RESULT2" ]; then
    echo "Unusual user path concoction $RESULT $RESULT2"
    exit 1
fi
RESULT=`cat bin/test`
if [ "$RESULT" != "$RESULT2" ]; then
    echo "Unusual bin path concoction $RESULT $RESULT2"
    exit 1
fi

$ATBUILD compile


echo "****************PUBLISHPRODUCT TEST**************"
cd $DIR/tests/fixtures/publish_product
$ATBUILD

if [ ! -f "bin/executable" ]; then
    echo "No executable"
    exit 1
fi

if [ ! -f "bin/executable.swiftmodule" ]; then
    echo "No module (executable)"
    exit 1
fi

if [ ! -f "bin/library.swiftmodule" ]; then
    echo "No module (library)"
    exit 1
fi

if [ ! -f "bin/library.a" ]; then
    echo "No library"
    exit 1
fi

echo "****************NONSTANDARD TEST**************"
cd $DIR/tests/fixtures/nonstandard_package_file
$ATBUILD -f nonstandard.atpkg

echo "****************AGRESSIVE TEST**************"
cd $DIR/tests/fixtures/agressive
if $ATBUILD 2&> /tmp/warnings.txt; then
    echo "No tool specified but passed anyway?"
    exit 1
fi
if ! grep "No tool for task agressive.default; did you forget to specify it?" /tmp/warnings.txt; then
    echo "Got an error other than one prompting for the correct tool"
    exit 1
fi

echo "****************SHADOW TEST*********************"
cd $DIR/tests/fixtures/depend_default
if $ATBUILD build-tests; then
    echo "default task was shadowed; expected a failure but got a pass"
    exit 1
fi

echo "****************WARNING TEST*********************"
cd $DIR/tests/fixtures/warnings
$ATBUILD > /tmp/warnings.txt
if ! grep "germany" /tmp/warnings.txt; then
    echo "Was not warned about invalid task key"
    exit 1
fi

if ! grep "poland" /tmp/warnings.txt; then
    echo "Was not warmed about invalid package key"
    exit 1
fi

cd $DIR/tests/fixtures/overlay
$ATBUILD --use-overlay got-overlay > /tmp/warnings.txt
if grep "Warning: Can't apply overlay no-such-overlay to task chained_overlays.child" /tmp/warnings.txt; then
    echo "Got a warning when building the overlay fixture"
    exit 1
fi

cd $DIR/tests/fixtures/chained_overlays
$ATBUILD --use-overlay no-such-overlay > /tmp/warnings.txt
if grep "Warning: Can't apply overlay no-such-overlay to task chained_overlays.child" /tmp/warnings.txt; then
    echo "Got a warning when building the chained_overlays fixture"
    exit 1
fi

echo "****************HELP TEST*********************"

if $ATBUILD atbuild --help; then
    echo "Unusual help exit code"
    exit 1
fi

echo "*****************XCS TEST**********************"
cd $DIR/tests/fixtures/xcs && $ATBUILD run-tests

echo "*****************STRICT CHECKS**********************"
if [ `uname` != "Darwin" ]; then
    echo "Not checking STRICT for non-Darwin platform"
else
    cd $DIR/tests/fixtures/xcs_strict
    if $ATBUILD run-tests; then
        echo "Expected a failure in xcs_strict"
        exit 1
    else
        echo "Strict failed as expected"
    fi
fi

echo "*****************OVERLAY CHECKS**********************"

cd $DIR/tests/fixtures/overlay
if $ATBUILD; then
    echo "Expected a failure in overlay"
    exit 1
fi

$ATBUILD --use-overlay got-overlay

cd $DIR/tests/fixtures/overlay_default
if $ATBUILD --use-overlay foo; then
    echo "Expected a failure in overlay"
    exit 1
fi

printf "\e[1m\e[32m***ATBUILD TEST SCRIPT PASSED SUCCESSFULLY*****\e[0m"