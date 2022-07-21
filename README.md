## Welcome to OpenCilk!

This repo contains infrastructure tools for building the OpenCilk 2.0
compiler, runtime, and productivity tools.  Specifically, it includes
scripts for building OpenCilk from source or downloading and
installing a pre-built docker image of OpenCilk.

### Supported systems

OpenCilk 2.0 has been tested on the following processor architectures:

- Intel x86 processors, Haswell and newer
- AMD x86 processors, Excavator and newer
- [Beta] Apple M1 and other 64-bit ARM processors

The present version has been tested on the following operating systems:

- Ubuntu 18.04 and 20.04
  - including via the Windows Subsystem for Linux v2 (WSL2) on Windows 10
- FreeBSD 13
- Fedora 34
- macOS 10.15, 11.6, and 12.4

### Summary of OpenCilk features

- The `cilk_spawn`, `cilk_sync`, and `cilk_for` keywords are enabled
  by using the `-fopencilk` compiler flag and including
  `<cilk/cilk.h>`.
- The `cilk_scope` keyword specifies that all spawns within a given
  lexical scope are guaranteed to be synced upon exiting that lexical
  scope.  The `cilk_scope` keyword can also be used as a hint that the
  runtime system should ensure that Cilk workers are initialized, in
  order to quiesce performance measurements.  Like the other Cilk
  keywords, `cilk_scope` is available by using the `-fopencilk`
  compiler flag and including `<cilk/cilk.h>`.
- The compiler is based on [LLVM 14][llvm-14-doc] and supports the
  usual [`clang`][clang-14-doc] options as well as advanced linking
  features, such as link-time optimization (LTO).
- Both C and C++ are supported, including all standards supported by
  LLVM 14.
- Prototype support for C++ exceptions is included.
- Experimental support for pedigrees and built-in deterministic
  parallel random-number generation is available.  To enable pedigree
  support, link the Cilk program with the pedigree library,
  `-lopencilk-pedigrees`.
- [Beta] OpenCilk 2.0 introduces language support for reducer
  hyperobjects.  A local or global variable can be made into a reducer
  by adding `cilk_reducer(I, R)` to its type, where `I` and `R`
  designate the identity and reduce functions for the reducer.
- Cilksan instrumentation for determinacy-race detection is enabled by
  using the `-fsanitize=cilk` compiler flag.  Cilksan supports
  reducers and Pthread mutex locks.  In addition, Cilksan offers an
  API for controlling race detection, which is available by including
  `<cilk/cilksan.h>`.
- Cilkscale instrumentation for scalability analysis and profiling is
  enabled by using the `-fcilktool=cilkscale` compiler flag.
  Cilkscale offers an API for analyzing user-specified code regions,
  which is made available by including `<cilk/cilkscale.h>`, and
  includes facilities for benchmarking an application on different
  numbers of parallel cores and visualizing the results.
- [Beta] Cilksan integrates with a [custom
  version](https://github.com/OpenCilk/rr) of the RR reverse debugger
  to enable interactive debugging of determinacy races.

OpenCilk 2.0 is largely compatible with Intel's latest release of Cilk
Plus.  Unsupported features include:

- The Intel Cilk Plus reducer library.
- Cilk Plus array-slice notation.
- Certain Cilk Plus API functions, such as `__cilkrts_set_param()`.

### How to get OpenCilk

Precompiled binaries for OpenCilk 2.0 are available for some systems
here:
https://github.com/OpenCilk/opencilk-project/releases/tag/opencilk%2Fv2.0.
To install, either download and run the appropriate shell archive
(i.e., the `.sh` file) or unpack the appropriate tarball.

These precompiled binaries require that standard system header files
and libraries are already installed.  These header files and libraries
can be obtained by installing a modern version of GCC (including
`g++`) on Linux or by installing a modern version of Xcode on macOS.

A docker image with OpenCilk 2.0 installed, based on Ubuntu 20.04, is
available here:
https://github.com/OpenCilk/opencilk-project/releases/download/opencilk%2Fv2.0/docker-opencilk-v2.0.tar.gz.
Some documentation on how to use the docker image can be found here:
[docker](docker).

For other systems, we recommend instructions for downloading and
building OpenCilk from source can be found here:
[INSTALLING.md](INSTALLING.md).

### Porting Cilk Plus code to OpenCilk

***Reducers:*** OpenCilk 2.0 no longer support the Intel Cilk Plus
reducer library and instead features a new syntax and implementation
for reducers as a beta feature.  The new reducer implementation allows
one to change a local or global variable into a reducer by adding
`cilk_reducer(I,R)` to the variable's type, where `I` and `R`
designate the identity and reduce functions for the reducer.  For
example, here is how a simple integer-summation reducer can be
implemented using the new reducer syntax:

```c
#include <cilk/cilk.h>

void zero(void *v) {
  *(int *)v = 0;
}

void plus(void *l, void *r) {
  *(int *)l += *(int *)r;
}

int foo(int *A, int n) {
  int cilk_reducer(zero, plus) sum = 0;
  cilk_for (int i = 0; i < n; ++i)
    sum += A[i];
  return sum;
}
```

To port a Cilk Plus program to OpenCilk, once all uses of unsupported features 
have been updated, make the following changes to your build process:

- When compiling the program, replace any uses of `-fcilkplus` with `-fopencilk`.
- When linking the program, replace any uses of `-lcilkrts` with `-fopencilk`.

### Major changes in Version 2.0

- [Beta] OpenCilk supports a new syntax and implementation of reducer
  hyperobjects.  This new implementation allows local and global
  variables in C and C++ to be declared to be a `cilk_reducer` type.
  Registration and deregistration of such reducer variables is
  automatic.
- Support for the Intel Cilk Plus reducer library has been removed.
- The OpenCilk compiler has been upgraded to be based on LLVM 14.
- Pedigrees are now correctly updated at both spawns and syncs.
- Pedigrees are now enabled simply by linking the pedigree library,
  `-lopencilk-pedigrees`, to the Cilk program.
- Version 2.0 includes numerous bug fixes and performance improvements
  over the previous version.

### Known issues

- We are preparing documentation for OpenCilk and posting it on the
  OpenCilk website, https://www.opencilk.org.
- Similarly to C/C++ programs, large stack allocations can cause memory
errores due to overflowing OpenCilk's cactus stack.
- There are some functions library and LLVM intrinsic functions that Cilksan
does not recognize.  When Cilksan fails to recognize such a function, it may
produce a link-time error of the form, `undefined reference to '__csan_FUNC'`
for some function name `__csan_FUNC`.
  - Please report these missing functions to us as bug reports when you
encounter them.
  - [Beta] To work around the issue, add the flag ``-mllvm
    -cilksan-bc-path=`find /path/to/opencilk/ -name "libcilksan.bc"`
    `` to your command to compile the Cilk program.
  - If the above work around does not work for you, please let us
know.  Meanwhile, you can work around the issue by adding the
following code to your program, replacing `__csan_FUNC` with the name
of the function in the error message:

```cpp
#ifdef __cilksan__
#ifdef __cplusplus
extern "C" {
#endif
void __csan_default_libhook(uint64_t call_id, uint64_t func_id, unsigned count);
void __csan_FUNC(uint64_t call_id, uint64_t func_id, unsigned count) {
  __csan_default_libhook(call_id, func_id, count);
}
#ifdef __cplusplus
}
#endif
#endif
```

### Useful links

- Instructions for building OpenCilk from source:  
  [INSTALLING.md](INSTALLING.md)

- Scripts for building a Docker image with OpenCilk:  
  [docker](docker)

- Link to the OpenCilk infrastructure GitHub repo:  
  <https://github.com/OpenCilk/infrastructure>

- Some simple demo Cilk programs:  
  <https://github.com/OpenCilk/tutorial>

- Additional demo Cilk programs:  
  <https://github.com/OpenCilk/applications>

- OpenCilk website:  
  <https://www.opencilk.org>

### Contact

Bug reports should be posted to the [GitHub issue
tracker](https://github.com/OpenCilk/opencilk-project/issues).  Other
queries and comments should be emailed to
[contact@opencilk.org](mailto:contact@opencilk.org).

### OpenCilk development team

- Tao B. Schardl, MIT — Director, Chief Architect
- I-Ting Angelina Lee, WUSTL — Director, Runtime Architect
- John F. Carr, consultant — Senior Programmer
- Dorothy Curtis, MIT — Project Manager
- Charles E. Leiserson, MIT — Executive Director
- Alexandros-Stavros Iliopoulos, MIT, postdoc
- Tim Kaler, MIT, postdoc

### Previous development team members

- Grace Q. Yin, MIT, intern

### Acknowledgments

OpenCilk is supported in part by the National Science Foundation,
under grant number CCRI-1925609, and in part by the [USAF-MIT AI
Accelerator](https://aia.mit.edu/), which is sponsored by United
States Air Force Research Laboratory under Cooperative Agreement
Number FA8750-19-2-1000.

Any opinions, findings, and conclusions or recommendations expressed
in this material are those of the author(s) and should not be
interpreted as representing the official policies or views, either
expressed or implied, of the United states Air Force, the
U.S. Government, or the National Science Foundation.  The
U.S. Government is authorized to reproduce and distribute reprints for
Government purposes notwithstanding any copyright notation herein.

[llvm-14-doc]:  https://releases.llvm.org/14.0.0/docs/index.html
[clang-14-doc]: https://releases.llvm.org/14.0.0/tools/clang/docs/index.html
