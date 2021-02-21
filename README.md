## Welcome to OpenCilk!

This repo contains infrastructure tools for building the OpenCilk 1.0 RC2
compiler, runtime, and productivity tools.  Specifically, it includes scripts
for building OpenCilk from source or downloading and installing a pre-built
docker image of OpenCilk.

### Supported systems

OpenCilk 1.0 RC2 is targeted to experienced Cilk users running Unix/Linux on
modern x86_64 processors (e.g., Haswell, Excavator, or newer).  The present
version has been tested on the following operating systems:

- Ubuntu 18.04 and 20.04
  - including via the Windows Subsystem for Linux v2 (WSL2) on Windows 10
- FreeBSD 12.1
- Fedora 30
- Mac OS X 10.15

### Summary of OpenCilk features

- The `cilk_spawn`, `cilk_sync`, and `cilk_for` keywords are enabled by using
  the `-fopencilk` compiler flag and including `<cilk/cilk.h>`.
- The compiler is based on [LLVM 10][llvm-10-doc] and supports the usual
  [`clang`][clang-10-doc] options.
- Both C and C++ are supported, including all standards supported by LLVM 10.
- Prototype support for C++ exceptions is included.
- Experimental support for pedigrees and built-in deterministic parallel 
  random-number generation is available.  To enable pedigree support, compile and
  link all Cilk code with the flag `-fopencilk-enable-pedigrees`.
- Reducer hyperobjects are supported using the Intel Cilk Plus reducer library
  — i.e., the hyperobject headers from Intel Cilk Plus — except that it is
  not valid to reference the view of a C reducer after calling
  `CILK_C_UNREGISTER_REDUCER`.
- Cilksan instrumentation for determinacy-race detection is enabled by using the
  `-fsanitize=cilk` compiler flag.  Cilksan supports reducers and Pthread mutex
  locks.  In addition, Cilksan offers an API for controlling race detection, which
  is available by including `<cilk/cilksan.h>`.
- Cilkscale instrumentation for scalability analysis and profiling is enabled by
  using the `-fcilktool=cilkscale` compiler flag.  Cilkscale offers an API for
  analyzing user-specified code regions, which is made available by including
  `<cilk/cilkscale.h>`, and includes facilities for benchmarking an application
  on different numbers of parallel cores and visualizing the results.

OpenCilk 1.0 RC2 is largely compatible with Intel's latest release of Cilk
Plus.  Unsupported features include:

- Cilk Plus array slice notation.
- Certain functions of the Cilk Plus API, such as `__cilkrts_set_param()`.

[llvm-10-doc]:  https://releases.llvm.org/10.0.0/docs/index.html
[clang-10-doc]: https://releases.llvm.org/10.0.0/tools/clang/docs/index.html

### Useful links

- Instructions for building OpenCilk from source:  
  <https://github.com/OpenCilk/infrastructure/blob/release/INSTALLING.md>

- Scripts for building a Docker image with OpenCilk:  
  <https://github.com/OpenCilk/infrastructure/blob/release/docker>

- Link to the OpenCilk infrastructure GitHub repo:  
  <https://github.com/OpenCilk/infrastructure>

- Some simple demo Cilk programs:  
  <https://github.com/OpenCilk/tutorial>

- Additional demo Cilk programs:  
  <https://github.com/OpenCilk/applications>

- OpenCilk website:  
  <http://opencilk.org>

### Contact

Bug reports should be posted to the 
[GitHub issue tracker](https://github.com/OpenCilk/opencilk-project/issues)
or emailed to [bugs@opencilk.org](mailto:bugs@opencilk.org).
Other queries and comments should be emailed to
[contact@opencilk.org](mailto:contact@opencilk.org).

### OpenCilk development team

- Tao B. Schardl, MIT --- Director, Chief Architect
- I-Ting Angelina Lee, WUSTL --- Director, Runtime Architect
- John F. Carr, consultant --- Senior Programmer
- Dorothy Curtis, MIT --- Project Manager
- Charles E. Leiserson, MIT --- Executive Director
- Alexandros-Stavros Iliopoulos, MIT, postdoc
- Tim Kaler, MIT, postdoc
- Grace Q. Yin, MIT, intern
