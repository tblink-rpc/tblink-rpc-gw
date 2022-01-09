MKDV_MK:=$(abspath $(lastword $(MAKEFILE_LIST)))
TEST_DIR:=$(dir $(MKDV_MK))
include $(TEST_DIR)/../../common/prefix.mk
MKDV_TOOL ?= icarus

PYTHON_PATHS := $(shell $(PYTHON) -m mkdv files -t pythonPath tblink-rpc-gw:sim:tblink-rpc-ep-tb -f python)
MKDV_PYTHONPATH += $(PYTHON_PATHS)
ifeq (icarus,$(MKDV_TOOL))
  VL_SRCS := $(shell $(PYTHON) -m mkdv files -t verilogSource -t systemVerilogSource tblink-rpc-gw:sim:tblink-rpc-ep-tb -f vl)
  VL_INCS := $(shell $(PYTHON) -m mkdv files -i -t verilogSource -t systemVerilogSource tblink-rpc-gw:sim:tblink-rpc-ep-tb -f vl)
  TBLINK_RPC_PLUGIN := $(shell $(PYTHON) -m tblink_rpc_hdl simplugin vpi)
else
  VL_SRCS := $(shell $(PYTHON) -m mkdv files -t verilogSource -t systemVerilogSource tblink-rpc-gw:sim:tblink-rpc-ep-tb -f sv)
  VL_INCS := $(shell $(PYTHON) -m mkdv files -i -t verilogSource -t systemVerilogSource tblink-rpc-gw:sim:tblink-rpc-ep-tb -f sv)
  TBLINK_RPC_PLUGIN := $(shell $(PYTHON) -m tblink_rpc_hdl simplugin dpi)
  DPI_LIBS += $(TBLINK_RPC_PLUGIN)
endif
VPI_LIBS += $(TBLINK_RPC_PLUGIN)

MKDV_VL_SRCS    += $(VL_SRCS)
MKDV_VL_INCDIRS += $(VL_INCS)
TOP_MODULE = tblink_rpc_ep_tb

MKDV_PLUGINS += cocotb 
MKDV_COCOTB_MODULE = tblink_rpc_gw_tests.smoke
MKDV_RUN_ARGS += +tblink.launch=native.loopback

include $(TEST_DIR)/../../common/defs_rules.mk

RULES := 1

include $(TEST_DIR)/../../common/defs_rules.mk


