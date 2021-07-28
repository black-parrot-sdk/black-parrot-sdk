# BlackParrot SDK [![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
The BlackParrot SDK is a collection of tools and example benchmark suites to demonstrate how to
develop for the BlackParrot core. BlackParrot implements a standard RV64IMAFDMSU ISA and so is
capable of running just about any program on top of Linux. However, due to the simulation overheads
of running Linux, it's often useful to run programs baremetal. We provide a variety of convenient
features for bare-metal programs, with and without accelerators attached.

# Getting started

## Prerequisites
### Centos (7 or 8)

    yum install autoconf automake libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel dtc gtkwave vim-common virtualenv

CentOS 7 requires a more modern gcc to build Linux. If you receive an error such as "These critical
programs are missing or too old: make" try

    scl enable devtoolset-8 bash

### Ubuntu (18.04 or 20.04)

    sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev wget byacc device-tree-compiler python gtkwave vim-common virtualenv python-yaml

cmake3 is required. This is the default on newer versions of Ubuntu, but not necessarily on old versions.

BlackParrot has been tested extensively on CentOS 7. We have many users who have used Ubuntu for
development. If not on these versions of these OSes, we suggest using a
Docker image.

Ubuntu on Windows WSL 2.0 seems to work for most things, but you may encounter errors with more complex operations. For instance, compiling Linux is known not to work in this environment. This is considered an experimental build.

## The SDK

### Quickstart: Download a pre-built toolchain (Alpha)

Pre-built programs and toolchains can be downloaded at this repo's [releases page](https://github.com/black-parrot-sdk/black-parrot-sdk/releases). These are intended for compute or bandwidth constrained users, as well as classes or labs which may not have the permissions required to install necessary pre-requisites. To use them instead of building the SDK yourself:

    make checkout # initialize submodules
    make pull_sdk # Download and unpack pre-built SDK

This will grab both the tools and a few pre-built benchmark suites. From there you should be able to
build further programs using the tool installation. Toolchains were built on Ubuntu 20.04 using this
[image](registry.gitlab.com/dpetrisko/black-parrot-sdk), but should run on any modern Linux
platform. We welcome contributions for other images and scripts to build for other platforms.

### Building the SDK

    make checkout # initialize submodules
    # Set whatever variables your platform requires in Makefile.platform
    make sdk  # you can use the -j N flag to parallelize
    make prog # only makes a subset of programs. See Makefile for the full list of commands

For each suite in this directory, `make <suite>` will build the tests within and copy the resulting
.riscv binaries to ./prog/suite/example.riscv

### Libperch
libperch is the BlackParrot firmware library. It includes sample linker scripts for supported SoC
platforms, start code for running bare-metal tests, emulation code for missing instructions and
firmware routines for printing, serial input and output and program termination.

libperch is automatically compiled as part of the toplevel `make sdk` target. It is automatically
installed to ./lib/. Users should link this library when compiling a new bare-metal program for
BlackParrot.

### PanicRoom (aka bsg\_newlib)
PanicRoom is a port of newlib which packages a DRAM-based filesystem (LittleFS) along with a minimal
C library. By only implementing a few platform level operations, PanicRoom provides an operational
filesystem, eliminating the need for a complex host interface, It is automatically included with the
standard toolchain build as riscv64-unknown-elf-dramfs-, allowing benchmarks such as SPEC to run with minimal host overhead. For an example of how to use PanicRoom, see lfs\_demo in bp-demos

The SDK will install a program which allows you to convert a set of text files into the LitteFS
filesystem.

    Usage: dramfs_mklfs <block_size> <block_count> [input file(s)/dir(s)]
    Example dramfs_mklfs 128 64 hello.txt > lfs.c

From there, you can simply compile the lfs.c along with your main program and you will have access
to the filesystem using normal calls:

    int main() {
        // Initialize LFS
        dramfs_init();

        // Read from a file
        FILE *hello = fopen("hello.txt", "r");
        if(hello == NULL)
          return -1;

        char c;
        while((c = fgetc(hello)) != '\n') {
          bp_cprint(c);
        }
        bp_cprint('\n');

        fclose(hello);
        bp_finish(0);
        return 0;
    }

PanicRoom is also used for stdio operations like `printf`. So to use these functions you still need to generate a LittleFS configuration file(lfs.c) without any input files. You also need to call the `dramfs_init` function by building the start.S code in the perch directory with `-D_DRAMFS` flag alongside your program, or use the crt0.o generated at `lib/` as the default start code, or simply call it at the beginning of the main function.

### Building Linux
To build a SMP Linux executable for BlackParrot (make sure first to follow the above instructions for building the SDK):
```
make -j linux OPENSBI_NCPUS=<n>
./install/bin/dromajo --host --ncpus=<n> linux/linux.riscv # verify linux runs on the dromajo simulator
```
For further information read [the bp-linux README](https://github.com/black-parrot-sdk/bp-linux/blob/master/README.md).


### Adding a test
To add a new test to BlackParrot using our libraries is simple. Using our framework
  - add the new test C file in bp-demos/src
  - add the test to the test\_list in bp-demos/Makefile.frag
  - execute make bp-demos at the sdk root directory
This should build and install the test program to prog/bp-demos/foobar.riscv

If you want to use your own build structure, include ./Makefile.common to import notable
BlackParrot directory names as well as put the compiler on your path. To build a program,
use the following flags:
  - riscv64-unknown-elf-dramfs-gcc (for PanicRoom), riscv64-unknown-linux-gnu-gcc (for Linux)
  - -I$(BP\_INCLUDE\_DIR)
  - -L$(BP\_LIB\_DIR) -lperch
  - -T$(BP\_LINKER\_DIR)/riscv.ld

When you're done building your program, copy it into ./prog/custom/foobar.riscv or your favorite
SUITE/PROG combination

### Testing your test
RTL waveform debugging is hard. That's why, before we run new programs on BlackParrot, we want to
run them in Dromajo to verify that the software is working. Luckily, we've already built Dromajo as
part of make sdk. The version of Dromajo built has been modified to behave exactly as BlackParrot does
and is found here: https://github.com/bsg-external/dromajo. There is further documentation on
Dromajo in that repo.

    ./install/bin/dromajo --host [--enable_amo] [--ncpus=1] [--trace] ./prog/custom/foobar.riscv

will run your program. The --host options make Dromajo behave as BlackParrot, with a host interface
emulating our Verilog testbench. Once Dromajo passes your test, you're ready to run on BlackParrot!

### Debugging your test
Dromajo supports tracing. This option is enabled by adding --trace=0 to the dromajo invocation (0 indicates to start the trace after 0 instructions). The trace format is:

    0 3 0x0000000080000108 (0x06f00113) x 2 0x000000000000006f
    core_id priv_level pc (instruction) writeback_reg writeback_data
