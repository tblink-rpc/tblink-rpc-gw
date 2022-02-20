MKDV_MK:=$(abspath $(lastword $(MAKEFILE_LIST)))
SYNTH_DIR:=$(dir $(MKDV_MK))
include $(SYNTH_DIR)/../common/prefix.mk
MKDV_TOOL ?= openlane
MKDV_TIMEOUT ?= 1ms

QUARTUS_FAMILY ?= "Cyclone V"
QUARTUS_DEVICE ?= 5CGXFC7C7F23C8

#QUARTUS_FAMILY ?= "Cyclone 10 LP"
#QUARTUS_DEVICE ?= 10CL025YE144A7G

TOP_MODULE = tblink_rpc_cmdproc_1_1

SDC_FILE=$(SYNTH_DIR)/$(TOP_MODULE).sdc

include $(SYNTH_DIR)/../common/defs_rules.mk
include $(MKDV_CACHEDIR)/files.mk

RULES := 1

include $(SYNTH_DIR)/../common/defs_rules.mk

$(MKDV_CACHEDIR)/files.mk : 
	mkdir -p $(MKDV_CACHEDIR)
	$(PYTHON) -m mkdv filespec $(SYNTH_DIR)/filespec.yaml \
		-t mk -o $@

