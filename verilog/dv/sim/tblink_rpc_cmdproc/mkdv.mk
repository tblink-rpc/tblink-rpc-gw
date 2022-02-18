MKDV_MK:=$(abspath $(lastword $(MAKEFILE_LIST)))
TEST_DIR:=$(dir $(MKDV_MK))
include $(TEST_DIR)/../../common/prefix.mk
MKDV_TOOL ?= icarus
MKDV_TIMEOUT ?= 1ms

VLSIM_CLKSPEC += clock=10ns
VLSIM_OPTIONS += -Wno-fatal

ifeq (icarus,$(MKDV_TOOL))
  RUN := $(shell $(PYTHON) -m mkdv files $(TEST_DIR)/filespec_vl.yaml)
  VL_SRCS := $(shell cat $(TEST_DIR)/vl_srcs.txt)
  VL_INCS := $(shell cat $(TEST_DIR)/vl_incs.txt)
  TBLINK_RPC_PLUGIN := $(shell $(PYTHON) -m tblink_rpc_hdl simplugin vpi)
  VPI_LIBS += $(TBLINK_RPC_PLUGIN)
else
  RUN := $(shell $(PYTHON) -m mkdv files $(TEST_DIR)/filespec_sv.yaml)
  VL_SRCS := $(shell cat $(TEST_DIR)/vl_srcs.txt)
  VL_INCS := $(shell cat $(TEST_DIR)/vl_incs.txt)
  TBLINK_RPC_PLUGIN := $(shell $(PYTHON) -m tblink_rpc_hdl simplugin dpi)
  DPI_LIBS += $(TBLINK_RPC_PLUGIN)
endif
PYTHON_PATHS := $(shell cat pythonpaths.txt)
MKDV_PYTHONPATH += $(PYTHON_PATHS)

MKDV_VL_SRCS    += $(VL_SRCS)
MKDV_VL_INCDIRS += $(VL_INCS)
TOP_MODULE = tblink_rpc_cmdproc_tb

#MKDV_PLUGINS += cocotb 
MODULE = tblink_rpc_gw_tests.cmdproc.smoke
export MODULE
MKDV_RUN_ARGS += +tblink.launch=python.loopback
MKDV_RUN_ARGS += +module=tblink_rpc.rt.cocotb

include $(TEST_DIR)/../../common/defs_rules.mk

RULES := 1

include $(TEST_DIR)/../../common/defs_rules.mk


