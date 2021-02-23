# Welcome to OpenCilk

This prerelease version of OpenCilk is available as source code in
three git repositories.  You will need 1.5 GB of space for the source
code (mostly LLVM) plus 3 GB of space to build (total 4.5 GB).  You
will need a compiler capable of building LLVM.  Any compiler you are
likely to have installed on a modern multicore system should work.
This version only supports 64 bit x86 on Linux or FreeBSD.

## Install from source
Clone these repositories into sibling directories:

`git clone -b opencilk/beta3 https://github.com/OpenCilk/infrastructure`

`git clone -b opencilk/beta3 --single-branch https://github.com/OpenCilk/opencilk-project`

Put the runtime into a subdirectory of the compiler:

`git clone -b opencilk/beta3 -- https://github.com/OpenCilk/cheetah opencilk-project/cheetah`

Run `infrastructure/tools/build` with two or three arguments.  The first
argument is the absolute pathname of the parent directory of the
repositories.  The second argument is the pathname of a directory to
build OpenCilk.  The third argument, if present, tells the build
system how many parallel jobs to run.  Default parallelism is 10.

For example:

After completing `git clone` as above:

``$ infrastructure/tools/build `pwd` `pwd` /build 60``

OpenCilk takes a few CPU-hours to build on a modern system -- less
than 10 minutes on a 24 core Ryzen with a fast disk.  It might take
all day single threaded on an older machine.

---

## Usage

You can run the compiler out of its build tree, adding `/bin/clang` to
the build directory name. For example:

`./build/bin/clang fib.c -o fib -O3 -fopencilk`

You must have a chip with Intel's Advanced Vector Instructions (AVX).
This includes Sandy Bridge and newer Intel processor (released
starting in 2011) and Steamroller and newer AMD processors (released
starting in 2014).

On MacOSX, you will need an XCode or CommandLineTools installation to
provide standard system libraries and header files for clang.  To run
clang with those header files and libraries, invoke the clang binary
with xcrun, for example,

$ xcrun `pwd`/build/bin/clang
