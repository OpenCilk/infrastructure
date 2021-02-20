## Instructions for building OpenCilk from source

The prerelease version of OpenCilk is available as source code in three git
repositories, plus this infrastructure facilities repository.  You will need 1.8
GB of space for the source code (mostly LLVM) plus 3.5 GB of space to build
(total 5.3 GB).  You will need a compiler capable of building LLVM.  Any
compiler you are likely to have installed on a modern multicore system should
work.  OpenCilk 1.0 only supports 64-bit x86 on Linux or Unix-like operating
systems.

### Obtaining the OpenCilk source code

Clone the OpenCilk compiler, runtime, and productivity tool repositories.  The
Cheetah runtime and OpenCilk tool repositories must be cloned into
sub-directories of the OpenCilk project directory:

    git clone -b opencilk/v1.0-rc2 --single-branch https://github.com/OpenCilk/opencilk-project
    git clone -b opencilk/v1.0-rc2 https://github.com/OpenCilk/cheetah opencilk-project/cheetah
    git clone -b opencilk/v1.0-rc2 https://github.com/OpenCilk/productivity-tools opencilk-project/cilktools

Clone the OpenCilk infrastructure repository, which contains the OpenCilk build
script:

    git clone -b opencilk/v1.0-rc2 https://github.com/OpenCilk/infrastructure

### Building OpenCilk

Run the `infrastructure/tools/build` script with two or three arguments.  The
1st argument is the absolute pathname to the `opencilk-project` repository
directory.  The 2nd argument is the absolute pathname of a directory to build
OpenCilk.  The 3rd argument, if present, tells the build system how many
parallel jobs to run.  Default parallelism is equal to the number of logical
cores, or 10 if the number of cores is not detected.

For example:

    # ...git clone as above...
    infrastructure/tools/build $(pwd)/opencilk-project $(pwd)/build 60

OpenCilk takes a few CPU-hours to build on a modern system --- less than 10
minutes on a 24-core Ryzen with a fast disk.  It might take all day
single-threaded on an older machine.

To echo the OpenCilk build script call syntax, use the `--help` switch:

    infrastructure/tools/build --help

### Usage

You can run the OpenCilk C compiler out of its build tree, adding `/bin/clang`
to the build directory name.  Similarly, add `/bin/clang++` for the OpenCilk C++
compiler.

You must have a chip with Intel's Advanced Vector Instructions (AVX).  This
includes Sandy Bridge and newer Intel processors (released starting in 2011), and
Steamroller and newer AMD processors (released starting in 2014).

On MacOSX, you will need an XCode or CommandLineTools installation to
provide standard system libraries and header files for clang.  To run
clang with those header files and libraries, invoke the clang binary
with `xcrun`; for example:

    xcrun $(pwd)/build/bin/clang
