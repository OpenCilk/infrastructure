## Building a new docker image

To build a new docker image, first install docker on your system, if
it's not installed already.

For Ubuntu, follow the instructions
[here](https://docs.docker.com/engine/install/ubuntu/) to install
docker.  To use docker without superuser privileges, first run this
command:

    sudo usermod -aG docker $USER

Then either logout and login again or run the following command:

    newgrp docker

Verify that you can run docker without superuser privileges:

    docker run hello-world

Once docker is installed, run the build script in this directory to
build the docker image:

	./build-image.sh

## Using the docker image

To install the pre-build container image, first install docker.  On
Linux, users should be added to the docker group so docker commands do
not need root privileges to execute.  The image can then be loaded
into docker by running:

	docker load < docker-opencilk-v1.0.tar.gz

The docker image is constructed from an Ubuntu 20.04 base image, and
is built according to the procedures in the `Dockerfile` and
`build-image.sh` files.  This image is not intended to be standalone,
and is intended to be used as a base for your own Docker images.  It
contains all that is necessary to build and use OpenCilk's compiler
runtime, and tools, and additionally contains the OpenCilk source code
in `/usr/local/src/opencilk.tar.gz`.
