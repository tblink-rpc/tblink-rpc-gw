MKDV_MK:=$(abspath $(lastword $(MAKEFILE_LIST)))
SYNTH_DIR:=$(dir $(MKDV_MK))
include $(SYNTH_DIR)/../common/prefix.mk
MKDV_TOOL ?= openlane
MKDV_TIMEOUT ?= 1ms

QUARTUS_FAMILY ?= "Cyclone V"
QUARTUS_DEVICE ?= 5CGXFC7C7F23C8

#QUARTUS_FAMILY ?= "Cyclone 10 LP"
#QUARTUS_DEVICE ?= 10CL025YE144A7G

VL_SRCS := $(shell $(PYTHON) -m mkdv files -t verilogSource -t systemVerilogSource tblink-rpc::tblink-rpc-gw -f vl)
VL_INCS := $(shell $(PYTHON) -m mkdv files -i -t verilogSource -t systemVerilogSource tblink-rpc::tblink-rpc-gw -f vl)

MKDV_VL_SRCS    += $(VL_SRCS)
MKDV_VL_INCDIRS += $(VL_INCS)
TOP_MODULE = tblink_rpc_ctrl

SDC_FILE=$(SYNTH_DIR)/$(TOP_MODULE).sdc

include $(SYNTH_DIR)/../common/defs_rules.mk

RULES := 1

include $(SYNTH_DIR)/../common/defs_rules.mk


