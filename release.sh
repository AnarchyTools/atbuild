if [ ! -f artifacts-linux.zip ]; then
    echo "Missing artifacts-linux.zip"
    exit 1
fi 
if [ ! -f artifacts-osx.zip ]; then
    echo "Missing artifacts-osx.zip"
    exit 1
fi 
echo "version to tag:"
read version
rm -rf /tmp/build
unzip artifacts-linux.zip -d /tmp/build/
tar c -C /tmp/build bin | pixz -9 -o atbuild-${version}-linux.tar.xz
#the OSX on the other hand is in .atllbuild
rm -rf /tmp/build
mkdir -p /tmp/build/bin
unzip artifacts-osx.zip -d /tmp/build/
cp /tmp/build/.atllbuild/products/atbuild /tmp/build/bin/atbuild
tar c -C /tmp/build bin | pixz -9 -o atbuild-${version}-macosx.tar.xz