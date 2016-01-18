if [ ! -f artifacts-linux.tgz ]; then
    echo "Missing artifacts-linux.tgz"
    exit 1
fi 
if [ ! -f artifacts-osx.tgz ]; then
    echo "Missing artifacts-osx.tgz"
    exit 1
fi 
echo "version to tag:"
read version
tar xf artifacts-linux.tgz
tar c bin/ | pixz -9 -o atbuild-${version}-linux.tar.xz
#the OSX on the other hand is in .atllbuild
mkdir -p /tmp/build/bin
tar xf artifacts-osx.tgz -C /tmp/build/
cp /tmp/build/.atllbuild/products/atbuild /tmp/build/bin/atbuild
tar c -C /tmp/build bin | pixz -9 -o atbuild-${version}-macosx.tar.xz