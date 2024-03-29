MKDV_MK:=$(abspath $(lastword $(MAKEFILE_LIST)))
TEST_DIR:=$(dir $(MKDV_MK))
include $(TEST_DIR)/../../common/prefix.mk
MKDV_TOOL ?= icarus
MKDV_TIMEOUT ?= 1ms

VLSIM_CLKSPEC += clock=10ns
VLSIM_OPTIONS += -Wno-fatal

ifeq (icarus,$(MKDV_TOOL))
  TBLINK_RPC_PLUGIN := $(shell $(PYTHON) -m tblink_rpc_hdl simplugin vpi)
  VPI_LIBS += $(TBLINK_RPC_PLUGIN)
  BFM_SRCFILE := $(MKDV_CACHEDIR)/bfm/backends/cmdproc_bfm_vl.sv
else
  TBLINK_RPC_PLUGIN := $(shell $(PYTHON) -m tblink_rpc_hdl simplugin dpi)
  DPI_LIBS += $(TBLINK_RPC_PLUGIN)
  BFM_SRCFILE := $(MKDV_CACHEDIR)/bfm/backends/cmdproc_bfm_sv.sv
endif
MKDV_PYTHONPATH += $(PYTHON_PATHS)


TOP_MODULE = tblink_rpc_cmdproc_tb

#MKDV_PLUGINS += cocotb 
MODULE = tblink_rpc_gw_tests.cmdproc.smoke
export MODULE
MKDV_RUN_ARGS += +tblink.launch=python.loopback
MKDV_RUN_ARGS += +module=tblink_rpc.rt.cocotb

include $(TEST_DIR)/../../common/defs_rules.mk
include $(MKDV_CACHEDIR)/files.mk
MKDV_VL_SRCS += $(BFM_SRCFILE)

export MKDV_CACHEDIR

RULES := 1

include $(TEST_DIR)/../../common/defs_rules.mk


$(MKDV_CACHEDIR)/files.mk :
	mkdir -p $(MKDV_CACHEDIR)
ifeq (icarus,$(MKDV_TOOL))
	$(PYTHON) -m mkdv filespec $(TEST_DIR)/filespec_vl.yaml \
		-t mk -o $@
else
	$(PYTHON) -m mkdv filespec $(TEST_DIR)/filespec_sv.yaml \
		-t mk -o $@
endif

$(BFM_SRCFILE) : gen-bfms


