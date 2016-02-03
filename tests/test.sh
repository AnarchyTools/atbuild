#!/bin/bash
set -e

echo "**********THE ATBUILD TEST SCRIPT*************"

DIR=`pwd`
ATBUILD="`pwd`/.atllbuild/products/atbuild"
pwd

echo "****************SELF-HOSTING TEST**************"
$ATBUILD atbuild

echo "****************UMBRELLA TEST**************"
cd $DIR/tests/fixtures/umbrella_header
$ATBUILD

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

    cd $DIR/tests/fixtures/xcs_strict_2
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

echo "***ATBUILD TEST SCRIPT PASSED SUCCESSFULLY*****"