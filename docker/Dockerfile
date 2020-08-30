FROM ubuntu:18.04

# NOTE: Don't use ADD; ADD will decompress the file
COPY opencilk.tar.gz /usr/local/src/opencilk.tar.gz

# Note that it is possible to specify a sequence of RUN commands, but there
# are various issues with this practice. The first issue is that each separate
# RUN command creates an extra layer of information that is stored with the
# container, which significantly bloats the image. Essentially these layers are
# diffs, so if we extract the opencilk tar in a step separate from removing the
# extracted files then Docker still stores those files in one of the layers, thus
# causing the Docker image to increase in size.

# Step 1: Install build dependencies (TODO: may be possible to install less)
# Step 2: Untar, build, and install OpenCilk
# Step 3: Add the location of libopencilk.so to the search path by appending
#         its location to /etc/ld.so.conf; run ldconfig to pick up the change
# Step 4: Remove the build files and apt-get cache files
RUN echo "Installing packages..." \
  && apt-get update -qq > /dev/null \
  && apt-get install -qqy --no-install-recommends \
    cmake \
    g++-8 \
    gcc-8 \
    make \
    python-minimal \
    libpython2.7-stdlib \
    > /dev/null \
  && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 10 \
  && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 10 \
  && update-alternatives --install /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-8 10 \
  && echo "Building OpenCilk..." \
  && tar -C /usr/local/src -xzf /usr/local/src/opencilk.tar.gz \
  && mkdir -p /usr/local/src/opencilk/build \
  && /usr/local/src/opencilk/infrastructure/tools/build /usr/local/src/opencilk \
    /usr/local/src/opencilk/build 8 \
  && echo "Installing OpenCilk to default install location..." \
  && cmake --build /usr/local/src/opencilk/build --target install \
  && echo "Setting up ld path to include the path to libopencilk.so..." \
  && echo "Cleaning temporary files..." \
  && rm -r /usr/local/src/opencilk \
  && rm -rf /var/lib/apt/lists/* \
  && echo "DOCKER IMAGE BUILT"