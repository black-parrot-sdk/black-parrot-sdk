TOP ?= $(shell git rev-parse --show-toplevel)

.PHONY: checkout
.PHONY: sdk_lite sdk sdk_clean
.PHONY: perch prog_lite prog
.PHONY: tidy_progs tidy bleach_all

all: apply_patches

include $(TOP)/Makefile.common
include $(TOP)/Makefile.tools
include $(TOP)/Makefile.prereq
include $(TOP)/Makefile.prog
include $(TOP)/Makefile.platform
include $(TOP)/Makefile.linker

## This is the list of target directories that tools and libraries will be installed into
override TARGET_DIRS := $(BP_SDK_BIN_DIR) $(BP_SDK_LIB_DIR) $(BP_SDK_INCLUDE_DIR) $(BP_SDK_LINKER_DIR) $(BP_SDK_PROG_TOUCH_DIR) $(BP_SDK_TOOLS_TOUCH_DIR) $(BP_SDK_WORK_DIR)
$(TARGET_DIRS):
	mkdir -p $@

# checkout submodules, but not recursively
checkout: | $(TARGET_DIRS)
	git fetch --all
	git submodule sync --recursive
	git submodule update --init

patch_tag ?= $(addprefix $(BP_SDK_TOUCH_DIR)/patch.,$(shell $(GIT) rev-parse HEAD))
apply_patches: | $(patch_tag)
$(patch_tag):
	$(MAKE) checkout
	git submodule update --init --recursive --recommend-shallow
	$(call patch_if_new,$(gnu_dir),$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain)
	$(call patch_if_new,$(gnu_dir)/binutils,$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain/binutils)
	$(call patch_if_new,$(gnu_dir)/gcc,$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain/gcc)
	$(call patch_if_new,$(gnu_dir)/gdb,$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain/gdb)
	cd $(gnu_dir); git submodule sync newlib
	cd $(gnu_dir); git submodule update --remote newlib
	$(call patch_if_new,$(riscv_tests_dir),$(BP_SDK_PATCH_DIR)/riscv-tests)
	$(call patch_if_new,$(riscv_tests_dir)/env,$(BP_SDK_PATCH_DIR)/riscv-tests/env)
	$(call patch_if_new,$(beebs_dir),$(BP_SDK_PATCH_DIR)/beebs)
	$(call patch_if_new,$(coremark_dir),$(BP_SDK_PATCH_DIR)/coremark)
	$(call patch_if_new,$(riscvdv_dir),$(BP_SDK_PATCH_DIR)/riscv-dv)
	$(call patch_if_new,$(linux_dir)/opensbi,$(BP_SDK_PATCH_DIR)/linux/opensbi)
	$(call patch_if_new,$(linux_dir)/buildroot,$(BP_SDK_PATCH_DIR)/linux/buildroot)
	touch $@
	@echo "Patching successful, ignore errors"

sdk_lite: apply_patches
	$(MAKE) prereqs
	$(MAKE) linker
	$(MAKE) -j1 bedrock
	$(MAKE) dromajo
	$(MAKE) gnudramfs

## This target makes the sdk tools
sdk: sdk_lite
	$(MAKE) gnu

sdk_bsg: sdk
	# Placeholder

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

prog_bsg: prog
	# Requires access to bsg_cadenv
	$(MAKE) -j1 bsg_cadenv
	# Requires access to spec2000
	$(MAKE) -j1 spec2000
	# Requires access to spec2006
	$(MAKE) -j1 spec2006
	# Requires access to spec2017
	$(MAKE) -j1 spec2017
	# Requires access to Synopsys VCS
	$(MAKE) -j1 riscv-dv
	# Needs opam build
	$(MAKE) -j1 riscv-arch
	# Requires patience
	$(MAKE) -j1 linux
	# Requires even more patience
	#$(MAKE) -j1 yocto
	# Requires yet more patience
	#$(MAKE) -j1 zephyr

## This target just wipes the whole repo clean.
#  Use with caution.
bleach_all:
	cd $(TOP); git clean -fdx; git submodule deinit -f .

# Extra convenience targets
# Pulls the latest tools and unpacks into the SDK install location
pull_sdk:
	$(eval SDK_URL := https://github.com/black-parrot-sdk/black-parrot-sdk/releases/download/)
	$(eval SDK_TAG := $(shell git describe --tags --abbrev=0))
	cd $(TOP); \
		$(CURL) -L $(SDK_URL)/$(SDK_TAG)/tools.tar.gz \
		| tar -xvz
	cd $(TOP); \
		$(CURL) -L $(SDK_URL)/$(SDK_TAG)/prog.tar.gz \
		| tar -xvz

# panic_room only build takes 15 minutes (versus 45 minutes for sdk_lite)
# to build on 4 cores; it leaves out unnecessary dependencies that make
# build failures more likely. (dromajo, dejagnu, gdb)
panic_room: checkout
	$(MAKE) linker
	$(MAKE) gnudramfs

