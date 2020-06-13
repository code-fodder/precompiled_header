## Example makefile

<pre>
#######################################################################
# Include the common makefiles:
#   - Variables:     Sets up the variables with some default values
include make_utils/common_targets.mk
#######################################################################
</pre>


## Example makefile.mk

<pre>
#######################################################################
# Include the common makefiles:
#   - Variables:     Sets up the variables with some default values
include make_utils/common_variables.mk
#######################################################################

# Project Name
PROJECT_NAME = test_proj

# Add your souce directories here
SOURCE_DIRS = \
	src \

# Include paths
INC_DIRS = \
	inc \

#######################################################################
# Include the common makefiles:
#   - shared_lib:     Sets the shared library options
#   - warnings:       Set the warning flags for various targets
#   - var_expansions: Generates lists of source, objects etc
#   - rules:          The build rules
include make_utils/common_shared_lib.mk
include make_utils/common_warnings.mk
include make_utils/common_var_expansions.mk
include make_utils/common_rules.mk
#######################################################################
</pre>
