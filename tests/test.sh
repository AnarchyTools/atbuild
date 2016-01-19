#!/bin/bash
set -e

echo "**********THE ATBUILD TEST SCRIPT*************"

DIR=`pwd`
ATBUILD="`pwd`/.atllbuild/products/atbuild"
pwd

echo "****************SELF-HOSTING TEST**************"
$ATBUILD atbuild

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

echo "***ATBUILD TEST SCRIPT PASSED SUCCESSFULLY*****"