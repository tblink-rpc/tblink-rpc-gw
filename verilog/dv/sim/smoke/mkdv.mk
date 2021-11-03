MKDV_MK:=$(abspath $(lastword $(MAKEFILE_LIST)))
TEST_DIR:=$(dir $(MKDV_MK))
MKDV_TOOL ?= icarus

MKDV_VL_SRCS += $(TEST_DIR)/smoke_tb.sv
TOP_MODULE = smoke_tb

MKDV_PLUGINS += cocotb pybfms
PYBFMS_MODULES += rv_bfms
MKDV_COCOTB_MODULE = tblink_rpc_gw_tests.smoke

include $(TEST_DIR)/../../common/defs_rules.mk

RULES := 1

include $(TEST_DIR)/../../common/defs_rules.mk


