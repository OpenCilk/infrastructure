To install the pre-build container image, first install docker.  On Linux, users
should be added to the docker group so docker commands do not need root
privileges to execute.  The image can then be loaded into docker by running:

	docker load < docker-opencilk-beta3.tar.gz

The docker image is constructed from an Ubuntu 18.04 base image, and is built
according to the procedures in the Dockerfile and build-image.sh files.  This
image is not intended to be standalone, and is intended to be used as a base for
your own Docker images.  It contains all that is necessary to build and use
OpenCilk's compiler and runtimes, and additionally contains the OpenCilk source
code in `/usr/local/src/opencilk.tar.gz`.
