TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

include $(BP_MK_DIR)/Makefile.tools
include $(BP_MK_DIR)/Makefile.prog

tools_lite: ## minimal SDK toolset
tools_lite:
	@$(MAKE) build.dromajo
	@$(MAKE) build.gnudramfs

tools: ## standard SDK tools
tools: tools_lite
	@$(MAKE) build.spike
	@$(MAKE) build.gnulinux

tools_bsg: ## additional SDK tools setup for BSG users
tools_bsg: tools
	# Placeholder

prog_lite: ## minimal programs for demo purposes
prog_lite:
	@$(MAKE) -j1 build.bedrock
	@$(MAKE) -j1 build.bootrom
	@$(MAKE) -j1 build.bp-demos
	@$(MAKE) -j1 build.bp-tests
	@$(MAKE) -j1 build.riscv-tests

prog: ## standard programs
prog: prog_lite
	@$(MAKE) -j1 build.coremark
	@$(MAKE) -j1 build.beebs

prog_bsg: ## additional programs for BSG users
prog_bsg: prog
	# Requires access to Synopsys VCS
	@$(MAKE) -j1 build.riscv-dv
	# Needs opam build
	@$(MAKE) -j1 build.riscv-arch
	# Requires access to spec2000
	@$(MAKE) -j1 build.spec2000
	# Requires access to spec2006
	@$(MAKE) -j1 build.spec2006
	# Requires access to spec2017
	@$(MAKE) -j1 build.spec2017
	# Requires patience
	@$(MAKE) -j1 build.linux

