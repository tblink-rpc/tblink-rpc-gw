MKDV_MK:=$(abspath $(lastword $(MAKEFILE_LIST)))
TEST_DIR:=$(dir $(MKDV_MK))
include $(TEST_DIR)/../../common/prefix.mk
MKDV_TOOL ?= icarus

VL_SRCS := $(shell $(PYTHON) -m mkdv files -t verilogSource -t systemVerilogSource tblink-rpc-gw:sim:tblink-rpc-ep-tb)
VL_INCS := $(shell $(PYTHON) -m mkdv files -i -t verilogSource -t systemVerilogSource tblink-rpc-gw:sim:tblink-rpc-ep-tb)

MKDV_VL_SRCS    += $(VL_SRCS)
MKDV_VL_INCDIRS += $(VL_INCS)
TOP_MODULE = tblink_rpc_ep_tb

MKDV_PLUGINS += cocotb 
MKDV_COCOTB_MODULE = tblink_rpc_gw_tests.smoke

include $(TEST_DIR)/../../common/defs_rules.mk

RULES := 1

include $(TEST_DIR)/../../common/defs_rules.mk


