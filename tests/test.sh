#!/bin/bash
set -e

echo "**********THE ATBUILD TEST SCRIPT*************"

ATBUILD="`pwd`/.atllbuild/products/atbuild"
pwd

echo "****************SELF-HOSTING TEST**************"
$ATBUILD atbuild

echo "*****************XCS TEST**********************"
cd tests/fixtures/xcs && $ATBUILD run-tests

echo "***ATBUILD TEST SCRIPT PASSED SUCCESSFULLY*****"