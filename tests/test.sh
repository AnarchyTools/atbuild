#!/bin/bash
set -e

echo "**********THE ATBUILD TEST SCRIPT*************"

DIR=`pwd`
ATBUILD="`pwd`/.atllbuild/products/atbuild"
pwd

echo "****************SELF-HOSTING TEST**************"
$ATBUILD atbuild

echo "****************HELP TEST*********************"
if [ $ATBUILD atbuild --help != 1 ]; then
    echo "Unusual help exit code"
    exit 1
fi

echo "*****************XCS TEST**********************"
cd tests/fixtures/xcs && $ATBUILD run-tests

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

$ATBUILD --overlay got-overlay

echo "***ATBUILD TEST SCRIPT PASSED SUCCESSFULLY*****"