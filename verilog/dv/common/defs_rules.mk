TBLINK_RPC_GW_VERILOG_COMMONDIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TBLINK_RPC_GWDIR:=$(abspath $(TBLINK_RPC_GW_VERILOG_COMMONDIR)/../../..)
PACKAGES_DIR:=$(TBLINK_RPC_GWDIR)/packages
DV_MK:=$(shell PATH=$(PACKAGES_DIR)/python/bin:$(PATH) python3 -m mkdv mkfile)
#DV_MK:=$(shell $(PACKAGES_DIR)/python/bin/python3 -m mkdv mkfile)

ifneq (1,$(RULES))

MKDV_PYTHONPATH += $(TBLINK_RPC_GW_VERILOG_COMMONDIR)/python
MKDV_PYTHONPATH += $(TBLINK_RPC_GW_VERILOG_COMMONDIR)/bfms/frontends/python
MKDV_PYTHONPATH += $(TBLINK_RPC_GWDIR)/python

include $(DV_MK)
else # Rules
include $(DV_MK)

.PHONY: gen-bfms
gen-bfms: 
	$(Q)$(PYTHON) -m tblink_bfms gen \
		-o bfm $(TBLINK_RPC_GW_VERILOG_COMMONDIR)/bfms/cmdproc_bfms.yaml \
		$(TBLINK_RPC_GW_VERILOG_COMMONDIR)/bfms/frontends \
		$(TBLINK_RPC_GW_VERILOG_COMMONDIR)/bfms/backends

endif

