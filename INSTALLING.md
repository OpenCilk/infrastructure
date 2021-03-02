## Instructions for building OpenCilk from source

OpenCilk is available as source code in three Git repositories, plus
this infrastructure facilities repository.  OpenCilk v1.0 is only
guaranteed to support 64-bit x86 on Linux or Unix-like operating
systems, although prototype support for ARM is included.

### Requirements

The build requirements for OpenCilk are largely consistent with those
for LLVM.  In summary, to build OpenCilk on a modern system running
Linux or MacOSX, you will need the following:
- A relatively recent version of Git.
- A relatively modern C/C++ compiler, such as GCC or Clang, that is
capable of building LLVM.  Any compiler you are likely to have
installed on a modern multicore system should work.
- CMake version 3.9 or newer.
- Approximately 1.8 GB of space for the source code (mostly LLVM) plus
3.5 GB of space to build, for a total of 5.3 GB.

More details on build requirements for LLVM can be found here:
<https://llvm.org/docs/GettingStarted.html#requirements>

### Quick start

Clone the OpenCilk infrastructure repository:

    git clone -b opencilk/v1.0-rc3 https://github.com/OpenCilk/infrastructure

Run the following script to get the OpenCilk source code:

    infrastructure/tools/get $(pwd)/opencilk

Then run the following script to build OpenCilk:

    infrastructure/tools/build $(pwd)/opencilk $(pwd)/build

You should now be ready to use OpenCilk.  Skip to [Usage](INSTALLING.md#Usage) now, or read
on for more explicit directions on building OpenCilk from source.

### Obtaining the OpenCilk source code

Clone the OpenCilk compiler, runtime, and productivity tool repositories.  The
Cheetah runtime and OpenCilk tool repositories must be cloned into
sub-directories of the OpenCilk project directory:

    git clone -b opencilk/v1.0-rc3 https://github.com/OpenCilk/opencilk-project
    git clone -b opencilk/v1.0-rc3 https://github.com/OpenCilk/cheetah opencilk-project/cheetah
    git clone -b opencilk/v1.0-rc3 https://github.com/OpenCilk/productivity-tools opencilk-project/cilktools

Note that, because these commands clone specific tags of the OpenCilk
repositories, it is normal for Git to report that each clone is in a
'detached HEAD' state after cloning.

Clone the OpenCilk infrastructure repository, which contains the OpenCilk build
script:

    git clone -b opencilk/v1.0-rc3 https://github.com/OpenCilk/infrastructure

### Building OpenCilk

Run the `infrastructure/tools/build` script with two or three arguments.  The
1st argument is the absolute pathname to the `opencilk-project` repository
directory.  The 2nd argument is the absolute pathname of a directory to build
OpenCilk.  The 3rd argument, if present, tells the build system how many
parallel jobs to run.  Default parallelism is equal to the number of logical
cores, or 10 if the number of cores is not detected.

For example:

    # ...git clone as above...
    infrastructure/tools/build $(pwd)/opencilk-project $(pwd)/build

Alternatively, to explicitly build OpenCilk using 8 build threads:

    # ...git clone as above...
    infrastructure/tools/build $(pwd)/opencilk-project $(pwd)/build 8

OpenCilk takes a few CPU-hours to build on a modern system --- less than 10
minutes on a 24-core Ryzen with a fast disk.  It might take all day
single-threaded on an older machine.

To echo the OpenCilk build script call syntax, use the `--help` switch:

    infrastructure/tools/build --help

> ***Advanced build options:*** If you wish, you can customize your
> build of OpenCilk beyond what the script provides --- e.g., to build
> additional LLVM subprojects --- by running the necessary CMake
> commands yourself.  When run, the `infrastructure/tools/build`
> script will print out the `cmake` commands it runs to build OpenCilk
> from source.  OpenCilk supports many of the same CMake build options
> as standard LLVM, which are documented here:
> <https://llvm.org/docs/CMake.html>.  If you wish to customize your
> OpenCilk build with these options, we recommend keeping `clang` in
> the list passed to `-DLLVM_ENABLE_PROJECTS` and `cheetah;cilktools`
> in the list passed to `-DLLVM_ENABLE_RUNTIMES`.

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

#### Optional: Installing OpenCilk

You can install OpenCilk into a directory of your choosing by
running the `cmake_install.cmake` script generated in the build
directory.  For example, run the following to install OpenCilk into
the directory `/tmp/llvm`:

    cd $(pwd)/build
    cmake -DCMAKE_INSTALL_PREFIX=/tmp/llvm -P cmake_install.cmake
    
### Troubleshooting

Here are a few common problems encountered when building from source,
along with suggested workarounds.

> The build fails with the error message, `collect2: error: ld returned 1 exit status`.

This error typically occurs when the build process exhausts the
physical memory available on the system.  Building OpenCilk from
source with many parallel build threads can consume a large amount of
physical memory, roughly speaking, in the tens of gigabytes.

**Fix:** Try reducing the number of parallel threads for building
OpenCilk.  Alternatively, try building OpenCilk from source using
`clang` and LLVM's linker, `lld`, which tends to consume less physical
memory than `ld`.

> The build fails with the error message, `unrecognized argument to '-fno-sanitize=' option: 'safe-stack'`.

This error typically occurs when the C and C++ compilers on the
system are mismatched, e.g., if `gcc` and `g++` refer to different
compiler versions on the system.

**Fix:** Make sure that the versions of `gcc` and `g++` installed on the
system are consistent.
