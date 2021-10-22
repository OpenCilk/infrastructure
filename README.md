## Welcome to OpenCilk!

This repo contains infrastructure tools for building the OpenCilk 1.1
compiler, runtime, and productivity tools.  Specifically, it includes
scripts for building OpenCilk from source or downloading and
installing a pre-built docker image of OpenCilk.

### Supported systems

OpenCilk 1.1 has been tested on the following processor architectures:

- Intel x86 processors, Haswell and newer
- AMD x86 processors, Excavator and newer
- [Beta] Apple M1 and other 64-bit ARM processors

The present version has been tested on the following operating systems:

- Ubuntu 18.04 and 20.04
  - including via the Windows Subsystem for Linux v2 (WSL2) on Windows 10
- FreeBSD 13
- Fedora 34
- Mac OS X 10.15 and 11.6

### Summary of OpenCilk features

- The `cilk_spawn`, `cilk_sync`, and `cilk_for` keywords are enabled by using
  the `-fopencilk` compiler flag and including `<cilk/cilk.h>`.
- The `cilk_scope` keyword specifies that all spawns within a given
  lexical scope are guaranteed to be synced upon exiting that lexical
  scope.  Like the other Cilk keywords, `cilk_scope` is available by
  using the `-fopencilk` compiler flag and including `<cilk/cilk.h>`.
- The compiler is based on [LLVM 12][llvm-12-doc] and supports the usual
  [`clang`][clang-12-doc] options.
- Both C and C++ are supported, including all standards supported by LLVM 12.
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

OpenCilk 1.1 is largely compatible with Intel's latest release of Cilk
Plus.  Unsupported features include:

- Cilk Plus array-slice notation.
- Certain Cilk Plus API functions, such as `__cilkrts_set_param()`.

### How to get OpenCilk

Precompiled binaries for OpenCilk 1.1 are available for some systems
here:
https://github.com/OpenCilk/opencilk-project/releases/tag/opencilk%2Fv1.1.
To install, either download and run the appropriate shell archive
(i.e., `.sh` file) or unpack the appropriate tarball.

A docker image for Ubuntu 20.04 with OpenCilk 1.1 installed is
available here:
https://github.com/OpenCilk/opencilk-project/releases/download/opencilk%2Fv1.1/docker-opencilk-v1.1.tar.gz.
Some documentation on how to use the docker image can be found here:
[docker](docker).

For other systems, instructions for downloading and building OpenCilk
from source can be found here: [INSTALLING.md](INSTALLING.md).

### Porting Cilk Plus code to OpenCilk

To port a Cilk Plus program to OpenCilk, once all uses of unsupported features 
have been updated, make the following changes to your build process:

- When compiling the program, replace any uses of `-fcilkplus` with `-fopencilk`.
- When linking the program, replace any uses of `-lcilkrts` with `-fopencilk`.

[llvm-12-doc]:  https://releases.llvm.org/12.0.0/docs/index.html
[clang-12-doc]: https://releases.llvm.org/12.0.0/tools/clang/docs/index.html

### Major changes in Version 1.1

- [New] OpenCilk now supports the `cilk_scope` keyword for specifying
  a lexical scope in which all spawns are guaranteed to be synced upon
  exiting that scope.
- [Beta] Cilksan now integrates with a [custom
  version](https://github.com/OpenCilk/rr) of the RR reverse debugger
  to enable interactive debugging of determinacy races.
- AddressSanitizer can now check OpenCilk programs for memory errors.
- The OpenCilk compiler has been upgraded to be based on LLVM 12.
- Cilkscale now links correctly when building shared libraries with
  the `-fcilktool=cilkscale` flag.
- OCaml bindings to Tapir in the compiler have been updated, thanks to
  [@Willtor](https://github.com/Willtor).
- Version 1.1 includes many bug fixes and performance improvements
  over version 1.0, including performance improvements to the runtime.

### Known issues

- We are preparing more complete documentation for OpenCilk, including the 
Cilkscale and Cilksan APIs.  Stay tuned!
- The OpenCilk runtime system limits the number of active reducers to 1024.
- Similarly to C/C++ programs, large stack allocations can cause memory
errores due to overflowing OpenCilk's cactus stack.
- There are some functions library and LLVM intrinsic functions that Cilksan
does not recognize.  When Cilksan fails to recognize such a function, it may
produce a link-time error of the form, `undefined reference to '__csan_FUNC'`
for some function name `__csan_FUNC`.
  - Please report these missing functions to us as bug reports when you
encounter them.
  - While we prepare a fix for the issue, you can work around the issue
by adding the following code to your program, replacing `__csan_FUNC` with
the name of the function in the error message:
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
  <http://opencilk.org>

### Contact

Bug reports should be posted to the 
[GitHub issue tracker](https://github.com/OpenCilk/opencilk-project/issues)
or emailed to [bugs@opencilk.org](mailto:bugs@opencilk.org).
Other queries and comments should be emailed to
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
