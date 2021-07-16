export BP_SDK_DIR ?= $(shell git rev-parse --show-toplevel)

.PHONY: checkout
.PHONY: sdk_lite sdk sdk_clean
.PHONY: prog_lite prog
.PHONY: tidy_progs tidy bsg_cadenv bleach_all
.DEFAULT: sdk

include $(BP_SDK_DIR)/Makefile.common
include $(BP_SDK_DIR)/Makefile.tools
include $(BP_SDK_DIR)/Makefile.prog

## This is the list of target directories that tools and libraries will be installed into
override TARGET_DIRS := $(BP_SDK_BIN_DIR) $(BP_SDK_LIB_DIR) $(BP_SDK_INCLUDE_DIR) $(BP_SDK_TOUCH_DIR)
$(TARGET_DIRS):
	mkdir -p $@

# checkout submodules, but not recursively
checkout: | $(TARGET_DIRS)
	git fetch --all
	cd $(BP_SDK_DIR); git submodule update --init

# Pulls the latest tools and unpacks into the SDK install location
pull_sdk: checkout
	$(eval SDK_URL := https://github.com/black-parrot-sdk/black-parrot-sdk/releases/download/)
	$(eval SDK_TAG := $(shell git describe --tags --abbrev=0))
	cd $(BP_SDK_DIR); \
		$(CURL) -L $(SDK_URL)/$(SDK_TAG)/tools.tar.gz \
	   	| tar -xvz
	cd $(BP_SDK_DIR); \
		$(CURL) -L $(SDK_URL)/$(SDK_TAG)/prog.tar.gz \
	   	| tar -xvz

sdk_lite: checkout
	$(MAKE) -j1 bedrock
	$(MAKE) dromajo
	$(MAKE) gnudramfs

## This target makes the sdk tools
sdk: sdk_lite
	$(MAKE) gnu

# panic_room only build takes 15 minutes (versus 45 minutes for sdk_lite)
# to build on 4 cores; it leaves out unnecessary dependencies that make
# build failures more likely. (dromajo, dejagnu, gdb)
panic_room: checkout
	$(MAKE) gnudramfs

## Even the "lite" programs require the full sdk toolchain
prog_lite: sdk_lite
	$(MAKE) -j1 perch
	$(MAKE) -j1 bootrom
	$(MAKE) -j1 bp-demos
	$(MAKE) -j1 bp-tests

## This target makes all of the programs
prog: prog_lite
	$(MAKE) -j1 riscv-tests
	$(MAKE) -j1 coremark
	$(MAKE) -j1 beebs
	# Requires access to spec2000
	#$(MAKE) spec2000
	# Requires access to Synopsys VCS
	#$(MAKE) riscv-dv
	# Requires patience
	#$(MAKE) linux

sdk_clean:
	-$(MAKE) prog_clean
	-$(MAKE) tools_clean

tidy_progs:
	git submodule deinit -f riscv-tests coremark beebs spec2000 riscv-dv

tidy: tidy_progs
	git submodule deinit -f dromajo riscv-gnu-toolchain linux

bsg_cadenv:
	-cd $(BP_SDK_DIR); git clone git@github.com:bespoke-silicon-group/bsg_cadenv.git bsg_cadenv

## This target just wipes the whole repo clean.
#  Use with caution.
bleach_all:
	cd $(BP_SDK_DIR); git clean -fdx; git submodule deinit -f .

# Uncomment this to reduce clone times
#GIT_SUBMODULE_DEPTH ?= --depth 1000

