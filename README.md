![BlackParrot Logo](docs/bp_logo.png)

# BlackParrot SDK Repository

The BlackParrot SDK is a collection of tools and example benchmark suites to demonstrate how to
develop for [BlackParrot](https://github.com/black-parrot/black-parrot) which implements a standard RV64IMAFDCB + MSU ISA and so is
capable of running just about any program on top of Linux.
However, due to the simulation overheads of running Linux, it's often useful to run programs baremetal.
We provide a variety of convenient features for bare-metal programs, with and without accelerators attached.

Generally, this repo is included as part of a complete simulation environment.
However, the tools can be built directly here as well.
See each submodule for tips on any suite-specific configuration.


For most users, the following makefile targets will be the most useful:


    make tools_lite;         # minimal set of host tools
    make tools;              # standard host tools
    make tools_bsg;          # additional host tools for BSG users

    make prog_lite;          # minimal benchmark set
    make prog;               # standard benchmark set
    make prog_bsg;           # additional benchmark sets for BSG users


There are also common Makefile targets to maintain the repository:


    make checkout;       # checkout submodules. Should be done before building tools
    make bleach_all;     # wipes the whole repo clean. Use with caution
    make help;           # prints information about documented targets


For advanced usage or debugging, standardized targets are provided for each tool.
By default, these targets will only run if needed.
Following is an example of these targets for building [Dromajo](https://github.com/ChipsAlliance/dromajo):

    make patch.dromajo;   # checks out submodules and applies patches
    make repatch.dromajo; # forces patch
    make build.dromajo;   # builds the dromajo binary
    make rebuild.dromajo; # forces build


## Repository Structure


    +---black-parrot-sdk
        |---.gitlab-ci.common.yml # [x] YAML macros
        |---.gitlab-ci.yml        # [r] CI pipelines for building images
        |---Makefile              # [r] toplevel targets to run
        |---Makefile.common       # [x] macros, not often modified by users
        |---Makefile.env          # [w] black-parrot-sdk settings
        |---mk
            |---Makefile.tools              # [r] specific tool build targets
            |---Makefile.sdk                # [r] specific tool build targets
            |---Makefile.prog               # [r] specific tool build targets
        |---docker
            |---Dockerfile.centos7          # [r] Dockerfile for centos7
            |---Dockerfile.ubuntu24.04      # [r] Dockerfile for ubuntu24.04
            |---entrypoint.centos7.sh       # [x] entrypoint wrapper for centos7
            |---entrypoint.ubuntu24.04.sh   # [x] entrypoint wrapper for ubuntu24.04
            |---Makefile                    # [r] targets to create and run docker containers
            |---requirements.txt            # [r] python requirements for docker image
        |---ci
           |---common
              |---run-ci.sh                 # [r] wrapper script to run ci script on GitLab
              |---functions.sh              # [x] helper functions for bash scripts
           |---run-local.sh            # [w] wrapper script to run ci script locally
           |---functions.sh            # [w] helper functions for this repo
           |---smoke-simlist.sh        # [w] test that programs can be simulated


## Important Flags

Most variables have sensible defaults.
However, you may find these useful to override.

    BP_DIR          ?= $(TOP)             ; # root, nominally black-parrot-sdk/
    BP_WORK_DIR     ?= $(BP_DIR)/work     ; # intermediate build directory
    BP_INSTALL_DIR  ?= $(BP_DIR)/install  ; # final installation directory for toolchains
    BP_RISCV_DIR    ?= $(BP_DIR)/riscv    ; # final installation directory for RISC-V binaries

Additionally, if you have a different versions of Unix utilities you may find it useful to override their command in Makefile.common

## Docker Containerization

We provide Dockerfiles in docker/ to (mostly) match our internal build environments.
For performance, it is best to run natively if possible.
However, these are considered "self-documenting" examples of how to build these environments from scratch.
We also play clever tricks to allow users to mount the current repo in the image so that permissions are passed through.


    # Set the appropriate flags for your docker environment:
    #   DOCKER_PLATFORM: OS for the base image (e.g. ubuntu24.04, ...)
    #   USE_LOCAL_CREDENTIALS: whether to create the docker volume with your local uid/gid
    make -C docker docker-image; # creates a black-parrot-sdk docker image
    make -C docker docker-run;   # mounts black-parrot-sdk as a docker container


## Adding a test

To add a new test to BlackParrot using our libraries is simple. Using our framework
  - add the new test C file in bp-demos/src
  - add the test to the test\_list in bp-demos/Makefile.frag
  - execute make build.bp-demos at the sdk root directory
This should build and install the test program to prog/bp-demos/foobar.riscv

If you want to use your own build structure, include black-parrot-sdk/Makefile.env to import notable BlackParrot directory names as well as put the compiler on your path.
To build a program, use the following flags:
  - riscv64-unknown-elf-gcc (for PanicRoom), riscv64-unknown-linux-gnu-gcc (for Linux)
  - --specs=dramfs.specs
  - -I$(BP\_INCLUDE\_DIR)
  - -L$(BP\_LIB\_DIR) -lperch
  - -T$(BP\_LINKER\_DIR)/riscv.ld

When you're done building your program, copy it into ./riscv/custom/foobar.riscv or your favorite
SUITE/PROG combination

## Testing your test

RTL waveform debugging is hard.
That's why, before we run new programs on BlackParrot, we want to run them in Dromajo to verify that the software is working.
The version of Dromajo built by the SDK has been modified to behave exactly as BlackParrot: https://github.com/bsg-external/dromajo
There is further documentation on Dromajo in that repo.

    ./install/bin/dromajo [--ncpus=1] [--trace=N] ./riscv/custom/foobar.riscv

will run your program.
Once Dromajo passes your test, you're ready to run on BlackParrot!

## Debugging your test

Dromajo supports tracing.
This option is enabled by adding --trace=0 to the dromajo invocation (0 indicates to start the trace after 0 instructions).
The trace format is:


    0 3 0x0000000080000108 (0x06f00113) x 2 0x000000000000006f
    core_id priv_level pc (instruction) writeback_reg writeback_data


## libperch

libperch is the BlackParrot firmware library.
It includes sample linker scripts for supported SoC platforms, start code for running bare-metal tests, emulation code for missing instructions and firmware routines for printing, serial input and output and program termination.

libperch is automatically compiled as part of the toplevel `make sdk` target.
It is automatically installed to ./lib/. Users should link this library when compiling a new bare-metal program for BlackParrot.

## PanicRoom (aka libgloss-dramfs)

PanicRoom is a port of newlib which packages a DRAM-based filesystem (LittleFS) along with a minimal C library.
By only implementing a few platform level operations, PanicRoom provides an operational filesystem, eliminating the need for a complex host interface.
It is automatically included with the standard toolchain build as riscv64-unknown-elf-, allowing benchmarks such as SPEC to run with minimal host overhead.
For an example of how to use PanicRoom, see lfs\_demo in bp-demos.

A utility called dramfs\_mklfs allows you to convert a set of text files into the LitteFS filesystem.

    Usage: dramfs_mklfs <block_size> <block_count> [input file(s)/dir(s)]
    Example dramfs_mklfs 128 64 hello.txt > lfs.c

From there, you can simply compile the lfs.c along with your main program and you will have access to the filesystem using normal calls:


    int main() {
        // Initialize LFS
        // called by crt0.S
        // dramfs_fs_init();

        // Read from a file
        FILE *hello = fopen("hello.txt", "r");
        if(hello == NULL)
          return -1;

        char c;
        while((c = fgetc(hello)) != '\n') {
          putc(c);
        }
        putc('\n');

        fclose(hello);

        return 0;
        // Deinitialize LFS
        // called by crt0.S
        // dramfs_exit(0);
    }


PanicRoom is also used for stdio operations like `printf`.
To use these functions you still need to generate a LittleFS configuration file (lfs.c) without any input files.

## Issues

For maintenance tractability we provide very limited support for this repository.
Please triage build problems to see if they are with this repo or the tools themselves.
Most often, issues with building individual tools should be reported in their respective upstream repository.
Any issues reported with this repo should be reproducible by at least one of the provided Docker containers.
Issue categories we appreciate:
  - Makefile bugs / incompatibilities
  - Dockerfile bugs / incompatibilities
  - OS-specific build tweaks
  - Upstream links breaking

## PRs

We will gratefully accept PRs for:
  - Tool version bumps
  - New OS support through Dockerfiles (along with necessary Makefile changes)
  - GitLab CI enhancements

## GitLab CI Packaging

We provide packaged releases of these tools on [GitLab](https://gitlab.com/bespoke-silicon-group/black-parrot-sdk/-/packages).
These releases are highly experimental and there is no guarantee they will work on your machine, especially if there are OS differences.

