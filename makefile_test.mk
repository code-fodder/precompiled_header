#######################################################################
# Include the common makefiles:
#   - Variables:     Sets up the variables with some default values
include make_utils/common_variables.mk
#######################################################################

# Project Name
PROJECT_NAME = timer

POST_BUILD_TASKS  = make cleanpch ;
POST_BUILD_TASKS += $(ECHO) '$(COLOUR_MAK)Normal compilation ---------------------------------------------------$(COLOUR_RST)' ;
POST_BUILD_TASKS += make cleanall ; time make ;
POST_BUILD_TASKS += $(ECHO) '$(COLOUR_MAK)PCH compilation  -----------------------------------------------------$(COLOUR_RST)' ;
POST_BUILD_TASKS += make cleanall ; time make precompiled_header ;
POST_BUILD_TASKS += $(ECHO) '$(COLOUR_MAK)PCH re-compilation  --------------------------------------------------$(COLOUR_RST)' ;
POST_BUILD_TASKS += make cleanall ; time make precompiled_header ;
POST_BUILD_TASKS += make cleanpch ; make cleanall ;

#######################################################################
# Include the common makefiles:
include make_utils/common_executable.mk
include make_utils/common_warnings.mk
include make_utils/common_var_autofill.mk
include make_utils/common_rules.mk
#######################################################################
link_cmd =