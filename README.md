# OpenCilk infrastructure

This repo contains tools for building the OpenCilk compiler, runtime,
and productivity tools.  Specifically, it includes scripts for
building OpenCilk from source or building a Docker image of OpenCilk.

## Supported systems

OpenCilk has been tested on the following processor architectures:

- Intel x86 processors, Haswell and newer
- AMD x86 processors, Excavator and newer
- Various 64-bit ARM processors, including the Apple M1 and M2

The present version has been tested on the following operating systems:

- Recent versions of Ubuntu, including via the Windows Subsystem for
  Linux v2 (WSL2) on Windows 10
- Recent versions of macOS
- FreeBSD 13
- Recent versions of Fedora

## Summary of OpenCilk features

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
- The compiler is based on [LLVM][llvm-doc] and supports the usual
  `clang` options as well as advanced linking features,
  such as link-time optimization (LTO).
- Both C and C++ are supported, including all standards supported by
  LLVM 16.
- Support for deterministic parallel random-number generation is
  available.  To enable pedigree support, link the Cilk program with
  the pedigree library, `-lopencilk-pedigrees`.
- OpenCilk 2.0 and newer provides language support for reducer
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
- [Beta feature] Cilksan integrates with a [custom
  version](https://github.com/OpenCilk/rr) of the [RR reverse
  debugger](https://rr-project.org/) to enable interactive debugging
  of determinacy races.

OpenCilk is largely compatible with Intel's latest release of Cilk
Plus.  Unsupported features include:

- The Intel Cilk Plus reducer library.
- Cilk Plus array-slice notation.
- Certain Cilk Plus API functions, such as `__cilkrts_set_param()`.

## How to get OpenCilk

Precompiled binaries for OpenCilk are available for some systems here:
https://github.com/OpenCilk/opencilk-project/releases/.  To install,
either download and run the appropriate shell archive (i.e., the `.sh`
file) or unpack the appropriate tarball.  A Docker image with OpenCilk
installed is available from the same page.  Some documentation on how
to use the Docker image can be found here: [docker](docker).

These precompiled binaries require that standard system header files
and libraries are already installed.  These header files and libraries
can be obtained by installing a modern version of GCC (including
`g++`) on Linux or by installing a modern version of Xcode on macOS.

For other systems, we recommend instructions for downloading and
building OpenCilk from source can be found
[here](https://www.opencilk.org/doc/users-guide/build-opencilk-from-source/).

## Porting Cilk Plus code to OpenCilk

***Reducers:*** OpenCilk version 2.0 and newer does not support the
Intel Cilk Plus reducer library and instead features a new syntax and
implementation for reducers.  The new reducer implementation allows
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

## Useful links

- OpenCilk website:
  <https://www.opencilk.org>

- Instructions for building OpenCilk from source:
  <https://www.opencilk.org/doc/users-guide/build-opencilk-from-source/>

- Scripts for building a Docker image with OpenCilk:
  [docker](docker)

- Link to the OpenCilk infrastructure GitHub repo:
  <https://github.com/OpenCilk/infrastructure>

- Some simple demo Cilk programs:
  <https://github.com/OpenCilk/tutorial>

- Additional demo Cilk programs:
  <https://github.com/OpenCilk/applications>

- Notes for developing on the OpenCilk source:
  [DEVELOPER_NOTES.md](DEVELOPER_NOTES.md)

## Contact

Bug reports should be posted to the [GitHub issue
tracker](https://github.com/OpenCilk/opencilk-project/issues).  Other
queries and comments should be emailed to
[contact@opencilk.org](mailto:contact@opencilk.org).

## OpenCilk development team

- Tao B. Schardl, MIT — Director, Chief Architect
- John F. Carr, consultant — Senior Programmer
- Dorothy Curtis, MIT — Project Manager
- Bruce Hoppe, consultant — Documentation Specialist and Outreach Coordinator
- Charles E. Leiserson, MIT — Executive Director
- Tim Kaler, MIT, Research Scientist
- Xuhao Chen, MIT, Research Scientist

### Previous team members

- I-Ting Angelina Lee, WUSTL — Director, Runtime Architect
- Alexandros-Stavros Iliopoulos, MIT, postdoc
- Grace Q. Yin, MIT, intern

## Acknowledgments

OpenCilk is supported in part by the National Science Foundation,
under grant number CCRI-1925609, in part by the Department of Energy,
National Nuclear Security Administration under Award Number
DE-NA0003965, and in part by the [USAF-MIT AI
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

[llvm-doc]:  https://releases.llvm.org/
