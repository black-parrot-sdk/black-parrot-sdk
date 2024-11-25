TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

include $(BP_SDK_MK_DIR)/Makefile.sdk
include $(BP_SDK_MK_DIR)/Makefile.prog

checkout: ## checkout submodules, but not recursively
	@$(MKDIR) -p $(BP_SDK_BIN_DIR) \
		$(BP_SDK_LIB_DIR) \
		$(BP_SDK_INCLUDE_DIR) \
		$(BP_SDK_LINKER_DIR) \
		$(BP_SDK_PROG_TOUCH_DIR) \
		$(BP_SDK_TOOLS_TOUCH_DIR) \
		$(BP_SDK_RISCV_INCLUDE_DIR) \
		$(BP_SDK_RISCV_LIB_DIR) \
		$(BP_SDK_RISCV_LINKER_DIR) \
		$(BP_SDK_RISCV_UCODE_DIR) \
		$(BP_SDK_WORK_DIR)
	@$(GIT) fetch --all
	@$(GIT) submodule sync
	@$(GIT) submodule update --init

apply_patches: ## applies patches to submodules
apply_patches: build.patch
$(eval $(call bsg_fn_build_if_new,patch,$(CURDIR),$(BP_SDK_TOUCH_DIR)))
%/.patch_build: checkout
	# Disable long checkouts
	@$(CD) $(BP_SDK_GNU_DIR); $(GIT) config --local submodule.qemu.update none
	@$(CD) $(BP_SDK_GNU_DIR); $(GIT) config --local submodule.spike.update none
	@$(CD) $(BP_SDK_GNU_DIR); $(GIT) config --local submodule.dejagnu.update none
	@$(GIT) submodule sync --recursive
	@$(GIT) submodule update --init --recursive --recommend-shallow
	@$(call bsg_fn_patch_if_new,$(BP_SDK_GNU_DIR),$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_GNU_DIR)/gcc,$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain/gcc)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_GNU_DIR),$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_GNU_DIR)/binutils,$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain/binutils)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_GNU_DIR)/gcc,$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain/gcc)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_GNU_DIR)/gdb,$(BP_SDK_PATCH_DIR)/riscv-gnu-toolchain/gdb)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_RISCV_TESTS_DIR),$(BP_SDK_PATCH_DIR)/riscv-tests)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_RISCV_TESTS_DIR)/env,$(BP_SDK_PATCH_DIR)/riscv-tests/env)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_BEEBS_DIR),$(BP_SDK_PATCH_DIR)/beebs)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_COREMARK_DIR),$(BP_SDK_PATCH_DIR)/coremark)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_RISCVDV_DIR),$(BP_SDK_PATCH_DIR)/riscv-dv)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_LINUX_DIR)/opensbi,$(BP_SDK_PATCH_DIR)/linux/opensbi)
	@$(call bsg_fn_patch_if_new,$(BP_SDK_LINUX_DIR)/buildroot,$(BP_SDK_PATCH_DIR)/linux/buildroot)
	@$(ECHO) "Patching successful, ignore errors"

sdk_lite: # minimal SDK toolset
sdk_lite: apply_patches
	@$(MAKE) build.boost
ifeq ($(CENTOS7),1)
	@$(MAKE) build.python
endif
	@$(MAKE) -j1 build.bedrock
	@$(MAKE) build.dromajo
	@$(MAKE) build.gnudramfs

sdk: ## standard SDK tools
sdk: sdk_lite
	@$(MAKE) build.spike
	@$(MAKE) build.gnulinux

sdk_bsg: ## additional SDK setup for BSG users
sdk_bsg: sdk
	# Placeholder

prog_lite: ## minimal programs for demo purposes
prog_lite: apply_patches
	@$(MAKE) -j1 build.perch
	@$(MAKE) -j1 build.bootrom
	@$(MAKE) -j1 build.bp-demos
	@$(MAKE) -j1 build.bp-tests

prog: ## standard programs
prog: prog_lite
	@$(MAKE) -j1 build.riscv-tests
	@$(MAKE) -j1 build.coremark
	@$(MAKE) -j1 build.beebs

prog_bsg: ## additional programs for BSG users
prog_bsg: prog
	# Requires access to spec2000
	@$(MAKE) -j1 build.spec2000
	# Requires access to spec2006
	@$(MAKE) -j1 build.spec2006
	# Requires access to spec2017
	@$(MAKE) -j1 build.spec2017
	# Requires access to Synopsys VCS
	@$(MAKE) -j1 build.riscv-dv
	# Needs opam build
	@$(MAKE) -j1 build.riscv-arch
	# Requires patience
	@$(MAKE) -j1 build.linux
	# Requires yet more patience
	@$(MAKE) -j1 build.zephyr

#############################
# Extra convenience targets
#############################
pull_sdk: ## (experimental) pulls the latest tools and unpacks the SDK
	$(eval SDK_URL := https://github.com/black-parrot-sdk/black-parrot-sdk/releases/download/)
	$(eval SDK_TAG := $(shell git describe --tags --abbrev=0))
	@$(CD) $(BP_SDK_DIR); \
		$(CURL) -L $(SDK_URL)/$(SDK_TAG)/tools.tar.gz \
		| $(TAR) -xvz
	@$(CD) $(BP_SDK_DIR); \
		$(CURL) -L $(SDK_URL)/$(SDK_TAG)/prog.tar.gz \
		| $(TAR) -xvz

