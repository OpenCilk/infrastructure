## Welcome to OpenCilk!

This repo contains infrastructure tools for building the OpenCilk 1.0
compiler, runtime, and productivity tools.  Specifically, it includes
scripts for building OpenCilk from source or downloading and
installing a pre-built docker image of OpenCilk.

### Supported systems

OpenCilk 1.0 should work on the following processors:

- Intel x86 processors, Haswell and newer
- AMD x86 processors, Excavator and newer
- [Beta] Apple M1 and other 64-bit ARM processors

The present version has been tested on the following operating systems:

- Ubuntu 18.04 and 20.04
  - including via the Windows Subsystem for Linux v2 (WSL2) on Windows 10
- FreeBSD 13
- Fedora 32
- Mac OS X 10.15 and 11.2

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

OpenCilk 1.0 is largely compatible with Intel's latest release of Cilk
Plus.  Unsupported features include:

- Cilk Plus array-slice notation.
- Certain Cilk Plus API functions, such as `__cilkrts_set_param()`.

### Porting Cilk Plus code to OpenCilk

To port a Cilk Plus program to OpenCilk, once all uses of unsupported features 
have been updated, make the following changes to your build process:

- When compiling the program, replace any uses of `-fcilkplus` with `-fopencilk`.
- When linking the program, replace any uses of `-lcilkrts` with `-fopencilk`.

[llvm-10-doc]:  https://releases.llvm.org/10.0.0/docs/index.html
[clang-10-doc]: https://releases.llvm.org/10.0.0/tools/clang/docs/index.html

### Known issues

- We are preparing more complete documentation for OpenCilk, including the 
Cilkscale and Cilksan APIs.  Stay tuned!
- AddressSanitizer may not work correctly on OpenCilk programs.  For example,
OpenCilk programs employ stack switching that AddressSanitizer does not
currently recognize and handle correctly.  This may cause AddressSanitizer to
appear to hang and use a large amount of memory.
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
- When building shared libraries with Cilkscale, you may need to manually link
the Cilkscale dynamic library with the shared library, rather than simply use
`-fcilktool=cilkscale` at link time for Cilkscale to behave correctly.  The
Cilkscale dynamic library, named `libclang_rt.cilkscale.so` on Linux and
`libclang_rt.cilkscale_osx_dynamic.dylib` on Mac OS X, can be found in a
subdirectory under `lib` within the build or install directory of OpenCilk.

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
- Grace Q. Yin, MIT, intern
