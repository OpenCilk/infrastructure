#!/bin/sh

# TODO: No effort has yet gone into making this script portable, flexible, or robust.
#       At the moment, this file primarily serves as documentation of the process.

set -e

# Download the source code

echo "Downloading OpenCilk source..."

wget -O opencilk-project.tar.gz \
  https://github.com/OpenCilk/opencilk-project/archive/opencilk/beta3.tar.gz

wget -O cheetah.tar.gz \
  https://github.com/OpenCilk/cheetah/archive/opencilk/beta3.tar.gz

# Unpack the source code

echo "Unpacking OpenCilk source into a common directory..."

mkdir -p opencilk/infrastructure
cp -r ../tools opencilk/infrastructure/

mkdir -p opencilk/opencilk-project
tar -xf opencilk-project.tar.gz -C opencilk/opencilk-project --strip-components 1

mkdir -p opencilk/opencilk-project/cheetah
tar -xf cheetah.tar.gz -C opencilk/opencilk-project/cheetah --strip-components 1

echo "Cleaning up downloaded tar files..."

rm -f opencilk-project.tar.gz
rm -f cheetah.tar.gz

echo "Modifying scripts for use in Docker environment..."

# The build script does not build the lld target, which is part of the binary release.
sed -i 's/COMPONENTS=\"clang\"/COMPONENTS=\"clang;lld\"/g' opencilk/infrastructure/tools/build

# This turns off assertions in the compiler, shaving off > 600 MB in size from the binaries.
sed -i 's/OPENCILK_ASSERTIONS:=ON/OPENCILK_ASSERTIONS:=OFF/g' opencilk/infrastructure/tools/build

# Only build for the host architecture, shaving off > 600 MB from the binaries.
sed -i 's/cmake -D/cmake -DLLVM_TARGETS_TO_BUILD=host -D/g' opencilk/infrastructure/tools/build

# Tar the source. We want to copy in the tar ball to save space; if we copy it in
# uncompressed, docker will hold onto the uncompressed data even if we compress it
# later.

echo "Compressing OpenCilk source..."

rm -f opencilk.tar.gz

tar -czf opencilk.tar.gz opencilk

# We no longer need the uncompressed source

rm -rf opencilk

# Build the container itself

echo "Building Docker image..."

docker build -t opencilk:beta3 .

# Dump the container image

echo "Compressing the Docker image for binary distribution..."

docker save opencilk:beta3 | gzip > docker-opencilk-beta3.tar.gz
