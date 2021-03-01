#!/bin/sh

# TODO: No effort has yet gone into making this script portable, flexible, or robust.
#       At the moment, this file primarily serves as documentation of the process.

set -e

# Download the source code

echo "Downloading OpenCilk source..."

# Derive the OpenCilk version from the latest Git tag, and determine
# the image name and final tarball name from that tag.
TAG="$(git describe --tags --abbrev=0)"
IMAGE_NAME="$(echo "${TAG}" | sed 's/\//:/g')"
DOCKER_NAME="$(echo "${TAG}" | sed 's/\//-/g')"

wget -O opencilk-project.tar.gz \
  https://github.com/OpenCilk/opencilk-project/archive/"${TAG}".tar.gz

wget -O cheetah.tar.gz \
  https://github.com/OpenCilk/cheetah/archive/"${TAG}".tar.gz

wget -O cilktools.tar.gz \
  https://github.com/OpenCilk/productivity-tools/archive/"${TAG}".tar.gz

# Unpack the source code

echo "Unpacking OpenCilk source into a common directory..."

mkdir -p opencilk/infrastructure
cp -r ../tools opencilk/infrastructure/

mkdir -p opencilk/opencilk-project
tar -xf opencilk-project.tar.gz -C opencilk/opencilk-project --strip-components 1

mkdir -p opencilk/opencilk-project/cheetah
tar -xf cheetah.tar.gz -C opencilk/opencilk-project/cheetah --strip-components 1

mkdir -p opencilk/opencilk-project/cilktools
tar -xf cilktools.tar.gz -C opencilk/opencilk-project/cilktools --strip-components 1

echo "Cleaning up downloaded tar files..."

rm -f opencilk-project.tar.gz
rm -f cheetah.tar.gz
rm -f cilktools.tar.gz

echo "Modifying scripts for use in Docker environment..."

# The build script does not build the lld target, which is part of the binary release.
sed -i 's/COMPONENTS=\"clang\"/COMPONENTS=\"clang;lld\"/g' opencilk/infrastructure/tools/build

# This turns off assertions in the compiler, shaving off > 600 MB in size from the binaries.
sed -i 's/OPENCILK_ASSERTIONS=ON/OPENCILK_ASSERTIONS=OFF/g' opencilk/infrastructure/tools/build

# Only build for the host architecture, shaving off > 600 MB from the binaries.
# Use clang and lld to build OpenCilk
sed -i 's/cmake -D/cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_ENABLE_LLD=On -D/g' opencilk/infrastructure/tools/build

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

docker build -t "${IMAGE_NAME}" .

# Dump the container image

echo "Compressing the Docker image for binary distribution..."

docker save "${IMAGE_NAME}" | gzip > docker-"${DOCKER_NAME}".tar.gz
