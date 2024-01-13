# Notes for OpenCilk developers

This document is meant for anyone modifying the OpenCilk codebase,
that is, the code in the opencilk-project, cheetah, or
productivity-tools repos.  If you are trying to debug a problem with
the OpenCilk system, or if you are conducting research that involves
modifying these codebases, you may find these notes helpful.

# Working with LLVM and the OpenCilk compiler

Because the OpenCilk compiler is based on LLVM, the techniques for
working with LLVM can be used to on the OpenCilk compiler as well.
These notes describe some of the techniques that have proven useful
for working with LLVM IR in debugging the OpenCilk compiler.

These notes assume that the reader has some basic familiarity with
LLVM and reading LLVM IR.  For more information on LLVM, consult the
[LLVM documentation](https://llvm.org/docs/).

## Note: Tapir

The OpenCilk compiler uses the ***Tapir*** extension to LLVM IR to
compile Cilk code.  Tapir adds three instructions to LLVM IR to
express task parallelism.  These instructions allow the OpenCilk
compiler to understand and optimize task-parallel code more
effectively than traditional compilers.  Tapir is described in a
[paper at PPoPP 2017](https://dl.acm.org/doi/10.1145/3155284.3018758)
and an [ACM TOPC article](https://dl.acm.org/doi/10.1145/3365655).

In the following notes, unless otherwise specified, any instructions
and notes concerning LLVM IR apply to Tapir as well.

## How to emit LLVM IR: `-S -emit-llvm`

To make `clang` emit LLVM IR for a given C or C++ program, pass the
additional flags `-S -emit-llvm` when compiling the program.  For
example, if `foo.c` is a C program:

```console
clang -c foo.c -O1 -S -emit-llvm -o foo.ll
```

Similarly, if `foo.cpp` is a C++ program:

```console
clang++ -c foo.cpp -O1 -S -emit-llvm -o foo.ll
```

These examples will emit the LLVM IR output into `foo.ll`.

As these examples show, you can pass other compilation flags to
`clang` in addition to `-S -emit-llvm`, including `-fopencilk` and any
optimization flags.  In that case, the resulting LLVM IR will reflect
the specified optimizations.

> [!NOTE]
> The `-S` flag instructs `clang` to emit human-readable LLVM
> IR.  If you pass `-emit-llvm` without `-S` to `clang`, then it will
> output LLVM bitcode.  Many LLVM tools can operate on LLVM bitcode
> directly, but it is not human-readable.

### How to emit Tapir: `-ftapir=none`

If you compile a Cilk program with `-fopencilk`, the OpenCilk compiler
will compile and optimize the code and then *lower* the Tapir
instructions to calls to the OpenCilk runtime system.  If you emit the
LLVM IR for that program using `-S -emit-llvm`, the resulting LLVM IR
file will not contain any Tapir instructions, but instead contain the
LLVM IR after the Tapir instructions have been lowered to calls to the
OpenCilk runtime system.

To emit the LLVM IR *before* Tapir lowering --- that is, to get the
LLVM IR with the Tapir instructions --- pass the additional flag
`-ftapir=none` to `clang` at compile time.

For example, if `foo.c` is a Cilk program, then the command

```console
clang -c foo.c -fopencilk -O1 -S -emit-llvm -o foo.ll
```

will emit the LLVM IR after all Tapir instructions lowered to calls to
the OpenCilk runtime system.  In contrast, the command

```console
clang -c foo.c -fopencilk -O1 -S -emit-llvm -o foo.ll -ftapir=none
```

will emit the LLVM IR with all Tapir instructions, that is, before the
Tapir instructions have been lowered.

## Editor modes for reading LLVM IR

Many editors support LLVM IR modes that make reading LLVM IR easier.
LLVM IR modes for some editors are also available in the
opencilk-project repo, under `llvm/utils`.

## How to run specific LLVM passes: `opt`

The `opt` tool allows you to run LLVM analysis and optimization passes
directly on a given LLVM IR file.  For example, the following command
runs the Scalar Replacement of Aggregates (SROA) optimization pass on
the LLVM IR file `foo.ll` and emit the output into `foo_sroa.ll`:

```console
opt foo.ll -passes='sroa' -S -o foo_sroa.ll
```

In the above command, the `-passes='sroa'` flag specifies the SROA
optimization pass; the `-S` flag directs `opt` to emit human-readable
LLVM IR, and `-o foo_sroa.ll` directs `opt` to emit the output to the
file `foo_sroa.ll`.

You can specify multiple passes for `opt` to run in order by
describing a custom pass pipeline.  For example, the following command
runs on `foo.ll` a pass pipeline consisting of the `sroa` and
`indvars` function passes followed by the `licm` loop pass with
MemorySSA enabled:

```console
opt foo.ll -passes='sroa,indvars,loop-mssa(licm)' -S -o foo_opt.ll
```

To run only an analysis pass, pass the `-print<analysis_pass_name>`
flag to `opt`.  For example, the following command runs Scalar
Evolution Analysis on `foo.ll`:

```console
opt foo.ll -passes='print<scalar-evolution>'
```

You can also run the default pipelines associated with standard
optimization levels --- `-O1`, `-O2`, or `-O3` --- using `opt` by
passing `-passes='default<O1>'`, `-passes='default<O2>'`, or
`-passes='default<O3>'`, respectively, to `opt`.  Run `opt -help` or
`opt -help-hidden` for more information on the flags that `opt`
recognizes.

## How to emit unoptimized LLVM IR that is ready for optimization: `-Xclang -disable-llvm-passes`

Suppose you want to run LLVM's optimizations by hand on a C/C++ or
Cilk program.  Recall that the LLVM compiler (and the OpenCilk
compiler) are organized such that the Clang front-end translates C or
C++ code into LLVM IR (or Tapir), and then the LLVM middle-end
optimizer performs analyses and optimizations on that LLVM IR.  In
this case, you might want `clang` to emit unoptimized LLVM IR, so you
can manually control the sequence of optimizations run on that IR
using `opt`.

It's important to note that `clang` will emit different IR to the LLVM
optimizer depending on the optimization level specified!  In
particular, `clang` will emit different metadata, LLVM intrinsics,
function attributes to guide LLVM optimizations only if optimization
level `-O1` or higher is specified.  Therefore, if you don't specify
an optimization level to `clang`, or if you pass `-O0` to `clang`,
then resulting LLVM IR will *not* by annotated and marked for
optimization passes to work correctly.

To direct `clang` to emit unoptimized LLVM IR that is correctly marked
and annotated for optimizations, pass the additional flags `-Xclang
-disable-llvm-passes`.  For example:

```console
clang++ foo.cpp -fopencilk -O3 -S -emit-llvm -o foo.ll -Xclang -disable-llvm-passes
```

## How to generate a picture of the LLVM IR: `opt -dot-cfg`

LLVM IR models each function in a program as a control-flow graph
(CFG), and it can be useful to view that CFG graphically, rather in
text form.  Given an LLVM IR file, such as `foo.ll`, you can direct
`opt` to generate a (Graphviz) dot file of the CFG for each function
using the `-dot-cfg` flag, e.g., as follows:

```console
opt foo.ll -dot-cfg
```

Note that the dot files generated by this command might be hidden
files in the current directory.  For example, if `foo.ll` contains a
function named `bar`, then `-dot-cfg` may produce a file named
`.bar.dot` in the current directory.

You can then convert a dot file to another format using the dot
program.  For example, the following command will generate a PDF from
`.bar.dot`:

```console
dot -Tpdf .bar.dot -o bar.pdf
```

> [!NOTE]
> There are other graphs related to LLVM IR other than the CFG
> that can be useful to look at as well, such as the call graph.  See
> the options named `--dot-<something>` in `opt -help` to see what other
> graphs `opt` can produce.

# Debugging the OpenCilk compiler

These notes describe tools and techniques that we have found to be
useful for debugging the OpenCilk compiler.

For more information on debugging LLVM, see [LLVM's documentation on
submitting bug reports](https://llvm.org/docs/HowToSubmitABug.html).

## Reduce the pass pipeline for a compiler bug using `reduce_pipeline.py`

LLVM 14 comes with a Python script, `reduce_pipeline.py`, for reducing
the compiler pass pipeline for triggering a compiler bug.  The script
is available in the source tree at `llvm/utils/reduce_pipeline.py`.

Here's an example of how to use `reduce_pipeline.py`.  Suppose that
the compiler crashes on some input `foo.ll` when using `-O3`
optimizations.  The following command uses `reduce_pipeline.py` to
reduce the passes from those run at `-O3` to a smaller set that also
triggers a crash:

```console
/path/to/llvm/utils/reduce_pipeline.py --opt-binary /path/to/build/bin/opt --passes "default<O3>" --input foo.ll --output foo_passes.ll
```

The arguments to this command are as follows:

- The `--opt-binary` argument specifies the path to a custom version
  of `opt` on which the crash occurs.  Although this argument is
  technically optional, it is generally needed when working with a
  custom build of LLVM or OpenCilk.
- The `--passes` argument is a string that specifies the initial set
  of passes to run, using the pass-pipeline syntax used by LLVM's new
  pass manager.  This string matches the passed to `opt
  -passes="<string>"`.  In this example, `"default<O3>"` is
  interpreted to be the set of passes run by default with `-O3`
  optimization enabled.
- The `--input` argument specifies the name of the LLVM IR input that
  triggers the crash.
- The `--output` argument specifies the name of the file where
  `reduce_pipeline.py` will save the LLVM IR to pass to the reduced
  set of passes to trigger a compiler crash.  This argument, although
  optional, is often useful, especially when the initial set of passes
  is large, e.g., `default<O3>`.  When the initial set of passes is
  large, the LLVM IR needed to trigger the crash on the reduced pass
  pipeline often won't match that needed to trigger the crash on the
  original pipeline.

The set of passes and the output LLVM IR generated by this script are
generally good candidates for further reducing the compiler bug using
`llvm-reduce`, described next.

## Reducing the input to a compiler bug using `llvm-reduce`

The `llvm-reduce` tool can also be used to reduce LLVM IR input that
leads to a crash.  The `llvm-reduce` tool takes an ***interestingness
test script*** that it uses to check if a given LLVM IR input contains
a problem.  This test script provides significant flexibility in how
it identifies interesting inputs.  A common case is that the script
will run a specific set of LLVM passes on the input via `opt` to
trigger a miscompilation.  But the script can alternatively run other
tools or executables to check whether the input is interesting.

The `llvm-reduce` tool only modifies the LLVM IR input, in an effort
to find a minimal LLVM IR input that exhibits interesting behavior.
The tool does *not* modify the test script.  For example, in the
common case where `llvm-reduce` is used to check whether a set of
passes triggers a miscompilation, `llvm-reduce` will not minimize the
set of passes run that trigger that miscompilation.  To reduce the set
of passes, use the `reduce_pipeline.py` script.

To use `llvm-reduce`, first create the interestingness test script to
check a given LLVM IR input.  For example, let's assume that script is
named `reduce-script` in the current working directory.  (More on that
shortly.)  Then, you can reduce an input LLVM IR file `foo.ll` as
follows:

```console
llvm-reduce --test=./reduce-script foo.ll
```

By default, `llvm-reduce` will generate a reduced LLVM IR input file
named `reduced.ll`.

In this example, `reduce-script` can be an arbitrary script that takes
an input file as `$1` and exits with `0`, if the input is interesting,
or `1`, otherwise.  Here is an example `reduce-script` that has been
used to reduce an input that triggered a crash in the OpenCilk compiler:

```sh
#!/bin/zsh

opt $1 -simplifycfg -keep-loops=false -tasks -S -o -

if [ $? -eq 134 ]; then
    exit 0
else
    exit 1
fi
```

The third line of the script runs `opt` on the input `$1` and the
passes `-simplifycfg`, with the option `-keep-loops=false`, and
`-tasks`, a Tapir-specific analysis pass in the OpenCilk compiler.
The following lines check if `opt` produced an error and returns the
appropriate interestingness result accordingly.

Here are some tips for writing your own interestingness test scripts
for `llvm-reduce`:

- Test the command you wish to run on the command line, and examine
  the return code using `echo $?`.
- Verify that the script runs as intended by invoking it directly from
  the command line, e.g., by running `./reduce-script <input>`.

### Example interestingness test scripts for `llvm-reduce`

Here are some more example scripts that have been used to debug
miscompilations by the OpenCilk compiler on different systems.  We
provide these here to illustrate some of the flexibility in writing
such scripts and to provide convenient examples that can be copied and
modified.

This script uses LLVM's new pass manager (which is enabled by default
as of LLVM 13) to invoke the `simplifycfg` pass with a particular set
of flags:

```sh
#!/bin/bash

opt $1 -passes="function<eager-inv>(simplifycfg<bonus-inst-threshold=1;no-forward-switch-cond;no-switch-range-to-icmp;no-switch-to-lookup;keep-loops;no-hoist-common-insts;no-sink-common-insts>)" -S -o -

if [ $? -eq 134 ]; then
    exit 0
else
    exit 1
fi
```

This script uses the new pass manager to invoke the
`simple-loop-unswitch` loop pass with MemorySSA enabled:

```sh
#!/bin/bash

opt $1 -passes="cgscc(devirt<4>(function<eager-inv>(loop-mssa(simple-loop-unswitch<nontrivial;trivial>))))" -S -o -

if [ $? -eq 134 ]; then
    exit 0
else
    exit 1
fi
```

This script runs the function-inlining pass and checks for a slightly
different return code.

```sh
#!/bin/bash

opt $1 -inline -S -o - > /dev/null 2>&1

if [ $? -eq 139 ]; then
    exit 0
else
    exit 1
fi
```

This script runs `llc` and `FileCheck` to check for a
problematic code pattern in the generated assembly.

```sh
#!/bin/zsh

LLC=~/Software/opencilk-project/build/bin/llc
FILECHECK=~/Software/opencilk-project/build/bin/FileCheck

${LLC} $1 -o - | ${FILECHECK} tmp.ll

if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi
```

## How to see what passes are run: `-print-pipeline-passes` and `-debug-pass-manager`

Suppose you want to see, when a given optimization level is specified,
what passes will run and in what order.  There are a couple of flags
you can choose from.

You can use the flag `-print-pipeline-passes` to get a string
describing the pass pipeline.  For example, the command

```console
opt fib.ll -S -o fib_opt.ll -passes='default<O1>' -print-pipeline-passes
```

produces a string describing the pass pipeline that runs when
compiling code with optimization level `-O1`.  This string is
compatible with the `-passes=` argument for `opt`.  In other words,
you can pass this string to `opt -passes=<string>` to run the same set
of passes.

> [!NOTE]
> The `-print-pipeline-passes` flag is best-effort only.

Alternatively, you can use the flag `-debug-pass-manager` to print
debugging information from LLVM's pass manager.  This debugging
information includes the code-transformation and analysis passes that
are run in the order they are run.  Although this flag provides
insight into what passes are running, the output of this flag is not a
string compatible with the `-passes=` flag.

## [Deprecated] How to see what passes are run: `-debug-pass=`

> [!NOTE]
> This flag is deprecated in the current version of LLVM.

Suppose you want to see, when a given optimization level is specified,
what passes will run and in what order.  You can use the flag
`-debug-pass=Arguments` to get this information.

When passing this flag to `clang`, preface it with the `-mllvm` flag,
e.g., as follows:

```console
clang -c fib.c -fopencilk -O3 -mllvm -debug-pass=Arguments
```

When using `opt`, however, the `-mllvm` flag is not necessary.  For
example:

```console
opt fib.ll -S -o fib_opt.ll -O3 -debug-pass=Arguments
```

Roughly speaking, the output of `-debug-pass=Arguments` is a list of
arguments you could pass to `opt` to replicate the sequence of
analyses and code transformations that run.  Note that the output of
`-debug-pass=Arguments` includes flags for all analyses and code
transformations that run, including analyses that run implicitly
before a given code transformation.  In other words, this list of
arguments might be more verbose than one necessarily needs to pass to
`opt`.

More generally, the `-debug-pass=` flag gives visibility into the
pipeline of LLVM passes that runs.  Here are several key uses of
`-debug-pass=`:

- `-debug-pass=Arguments` prints a list of pass arguments to pass to
  `opt`.
- `-debug-pass=Structure` prints the hierarchical structure of passes
  that will be run.
- `-debug-pass=Executions` prints each pass's name before it is
  executed.
- `-debug-pass=Details` prints details of each pass when it is
  executed, including information of analysis passes that are
  invalidated and rerun.

## [Deprecated] Reducing a compiler crash using `bugpoint`

Suppose you are debugging a compiler crash when its running
optimizations on a particular input.  For example, suppose that the
compiler is crashing during some optimization pass when it compiles a
large input file `foo.cpp` with optimization level `-O3`.  The size of
the input file and the number of passes can make pinpointing this
crash particularly difficult.

In such cases, the `bugpoint` tool can help identify a minimal input
and sequence of passes that triggers the crash.  Here are some common
steps for using `bugpoint` to bisect the crash:

1. Generate unoptimized LLVM IR for the input file:
   ```console
   clang++ -c foo.cpp -fopencilk -S -emit-llvm -o foo.ll -O3 -Xclang -disable-llvm-passes
   ```
2. Confirm that the suspected optimization flags in `opt` produce the
   crash.  In this example, we might verify that the following command
   result crashes:
   ```console
   opt foo.ll -S -o foo_opt.ll -O3
   ```
3. Run `bugpoint` on the LLVM IR input file with the same `opt` flags
   (except `-S` and `-o`):
   ```console
   bugpoint foo.ll -O3
   ```

The `bugpoint` tool should produce LLVM bitcode files containing
minimized versions of the input, along with `opt` flags to run to
reproduce a crash on those bitcode files.  These minimized versions
can often be adapted into LLVM regression tests for the bug.

To convert the LLVM bitcode into human-readable LLVM IR, simply use
`opt` with the `-S` flag, e.g., as follows:

```console
opt bugpoint-reduced-simplified.bc -S -o bugpoint-reduced-simplified.ll
```

> [!NOTE]
> Depending on the optimizations and the size of the input,
> `bugpoint` might take quite a while to run.  In addition, the crash
> that occurs on the minimized input and optimization flags might not
> exactly match the original crash, although the underlying problem
> might be the same.

For more information on `bugpoint`, see [its LLVM
documentation](https://llvm.org/docs/Bugpoint.html).

## Tricks for diving into an unfamiliar LLVM pass

Suppose you're trying to understand how a particular LLVM pass works.
For instance, the pass might be misbehaving on some input, and you
might not be familiar with that particular LLVM pass.  Here are some
tips and tricks for exploring how a particular LLVM pass works.

***Enabling internal debugging statements using `-debug-only=`*** Many
LLVM source files contain code to emit information about the pass for
internal debugging purposes.  This code typically appears within
`LLVM_DEBUG()` macros within the pass.  LLVM source files will also
define the `DEBUG_TYPE` macro to be the string to enable the debug
statements in that source file.  Typically, the value of `DEBUG_TYPE`
for an LLVM pass matches the `opt` flag for that pass.  To turn on
some source file's debug statements, use the `-debug-only=<string>`
flag with `opt` (or `-mllvm -debug-only=<string>` with `clang`).  For
example, the following command will enable debugging statements in the
InstructionCombining pass, LLVM's peephole optimizer:

```console
opt foo.ll -O1 -S -o foo_opt.ll -debug-only=instcombine
```

You can also enable debugging statements for multiple LLVM source
files by specifying the `DEBUG_TYPE` strings for all source files in a
comma-separated list.  For example, the following command enables
debugging statements in InstructionCombining and in Local, a source
file of LLVM utility routines that InstructionCombining uses:

```console
opt foo.ll -O1 -S -o foo_opt.ll -debug-only=instcombine,local
```

***Adding your own code to print out state:*** If you are working with
your own build of the compiler, most LLVM objects have useful
implementations of the output-stream operator, `<<`.  LLVM also
provides an output stream, `llvm::dbgs()`, for printing debug
information.  Hence, if there is an LLVM Value `V` --- which could be
an `Instruction`, `BasicBlock`, `Function`, `Module`, etc. --- whose
state you would like to examine at some point in the middle of an LLVM
pass, you can print it by adding `llvm::dbgs() << V` to the pass, then
recompiling the compiler and rerunning.

## How to see the LLVM IR before or after each pass: `-print-before-all` and `-print-after-all`

Suppose you want to examine the state of the LLVM IR before or after
each transformation pass that runs when compiling a program.  For
example, you might be trying to identify a transformation pass that
produces suspicious LLVM IR.

You can direct `clang` to emit the LLVM IR before each pass using the
flag `-mllvm -print-before-all`.  For example:

```console
clang -c fib.c -fopencilk -O3 -mllvm -print-before-all
```

Similarly, you can direct `clang` to emit the LLVM IR after each pass
using the flag `-mllvm -print-after-all`, e.g., as follows:

```console
clang -c fib.c -fopencilk -O3 -mllvm -print-after-all
```

When using these flags, the LLVM IR before or after each pass will be
annotated with the text `*** IR Dump Before <short pass description>
***` or `*** IR Dump After <short pass description> ***`.

You can similarly direct `opt` to emit the LLVM IR before or after
each pass it runs using `-print-before-all` or `-print-after-all`:

```console
opt fib.ll -O3 -S -o fib_opt.ll -print-before-all
opt fib.ll -O3 -S -o fib_opt.ll -print-after-all
```

When using `opt`, the `-mllvm` flag before `-print-before-all` or
`-print-after-all` is not necessary.

> [!NOTE]
> The `-print-before-all` and `-print-after-all` flags can
> produce a large amount of output, especially for a large input file or
> a large number of optimization passes.  It is often helpful to pipe
> that output to a separate file and then search the output after the
> fact.

# Debugging the OpenCilk runtime

TODO: Fill this in

# Debugging Cilksan and Cilkscale

TODO: Fill this in

