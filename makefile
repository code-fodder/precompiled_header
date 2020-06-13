#######################################################################
# Include the common makefiles:
#   - Variables:     Sets up the variables with some default values
include make_utils/common_targets.mk
#######################################################################

.PHONY: cleanpch
cleanpch:
	@$(ECHO) "$(COLOUR_ACT)Cleaning PCH files$(COLOUR_RST)"
	@$(RM) pch_*
