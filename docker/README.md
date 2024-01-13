## Building a new Docker image

To build a new Docker image, first install Docker on your system, if
it's not installed already.

For Ubuntu, follow the instructions
[here](https://docs.docker.com/engine/install/ubuntu/) to install
Docker, and follow the [Linux postinstall instructions]
(https://docs.docker.com/engine/install/linux-postinstall/) to use
Docker without superuser privileges.

Verify that you can run Docker without superuser privileges:

```console
docker run hello-world
```

Once Docker is installed, run the build script in this directory to
build the Docker image:

```console
TAG=<tag> ./build-image.sh
```

where `<tag>` gives the Git tag of the OpenCilk version to use,
e.g., `opencilk/v2.1`.

## Using the Docker image

To install the pre-build container image, first install Docker.  On
Linux, users should be added to the Docker group so `docker` commands do
not need root privileges to execute.  The image can then be loaded
into Docker by running:

```console
docker load < docker-opencilk-<version>.tar.gz
```

where `<version>` is the string describing the version of OpenCilk,
e.g., `v2.1`.

The Docker image is constructed from an Ubuntu 20.04 base image, and
is built according to the procedures in the `Dockerfile` and
`build-image.sh` files.  This image is not intended to be standalone,
and is intended to be used as a base for your own Docker images.  It
contains all that is necessary to build and use OpenCilk's compiler,
runtime, and tools, and additionally contains the OpenCilk source code
in `/usr/local/src/opencilk.tar.gz`.
