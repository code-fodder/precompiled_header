include make_utils/globals.mk
include make_utils/common_colours.mk

# Contains all the parameters
ALL_PARAMS := $(wordlist 1,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
#$(info ALL_PARAMS = $(ALL_PARAMS))

# Only take the first argument as local make goal
SECONDARY_PARAMS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
#$(info SECONDARY_PARAMS = $(SECONDARY_PARAMS))

# Filter out the non-targets - these are special build modifiers
# Sometimes the EXTRA_MAKE_GOALS will contain the build/clean target
# depending on the order of the parameters
EXTRA_MAKE_GOALS := $(filter-out debug release precompiled_header test verbose vverbose analyse target_x86Linux target_x64Linux,$(SECONDARY_PARAMS))

# Export all variables that are setup here - saves individually exporting variables
.EXPORT_ALL_VARIABLES:

# defaults - Note: these parameters are exported so that they are passed down to the sub makefiles
TARGET = x86Linux
BUILD_TYPE = debug
CC = g++
CXX = g++
RANLIB = ranlib
AR = ar
FLAGS_TARGET = -m32
BUILD_SUFFIX = d
FLAGS_VERBOSE =
FLAGS_SILENT =
FLAGS_ANALYSE =
USE_PRECOMPILED_HEADER = false

# Turn the secondary arguments into do-nothing targets for this makefile and pass them on to makefile.mk
# This means that if we do something like "make target_iMX8EVK print", then we setup the target varibles
# in a rule in this file, but we pass those variables on to the makefile.mk with the print goal - thus printing
# out the variables for the iMX8EVK target and not just the default one.
$(eval $(SECONDARY_PARAMS):;@:)

# Linux x86 c++ compiler
ifneq (,$(findstring target_x86Linux,$(ALL_PARAMS)))
  TARGET := x86Linux
  CC := gcc
  CXX := g++
  RANLIB := ranlib
  AR := ar
  PATH := $(PATH)
  FLAGS_TARGET := -m32
  MAKE_GOALS +=
endif

# Linux x64 c++ compiler
ifneq (,$(findstring target_x64Linux,$(ALL_PARAMS)))
  TARGET := x64Linux
  CC := gcc
  CXX := g++
  RANLIB := ranlib
  AR := ar
  PATH := $(PATH)
  FLAGS_TARGET := -m64
  MAKE_GOALS +=
endif

# Check if its a release build
ifneq (,$(findstring release,$(ALL_PARAMS)))
  BUILD_TYPE = release
  BUILD_SUFFIX =
endif

# Check if we want to use precompiled header
ifneq (,$(findstring precompiled_header,$(ALL_PARAMS)))
  USE_PRECOMPILED_HEADER = true
endif

# If verbose is specified then this just prints a little bit of extra debug info
# If vverbose is specified then print all the compile/link commands as well. Note that
# --no-print-directory is still specified because it is deemed unuseful (we have other
# debug that shows the precise makefile being called)
SILENT_MAKE = -s --no-print-directory
ifneq (,$(findstring vverbose,$(ALL_PARAMS)))
  SILENT_MAKE = --no-print-directory
  FLAGS_VERBOSE = vverbose
else ifneq (,$(findstring verbose,$(ALL_PARAMS)))
  FLAGS_VERBOSE = verbose
endif

# If analyse flag is specified then extra analysis tools are used (like cppcheck). Add more tools to the list as required
ifneq (,$(findstring analyse,$(ALL_PARAMS)))
  FLAGS_ANALYSE = analyse
endif

# Set the default target if not already set - this allows the makefile to overule it
.DEFAULT_GOAL := target_x86Linux

# The makefiles that we might find in a repo...
makefile_list =  $(wildcard $(CURDIR)/makefile.mk)
# Add make test if wanted
ifneq (,$(findstring test,$(ALL_PARAMS)))
  makefile_list += $(wildcard $(CURDIR)/makefile_test.mk)
endif

### THE MAIN RULE ###
# Set this as the default rule
.DEFAULT_GOAL = _run_make
.PHONY: _run_make
_run_make:
	@for mkfile in $(makefile_list) ; do \
		if [[ "$(FLAGS_VERBOSE)" != "" ]] ; then \
			$(ECHO) "$(COLOUR_MAK)$$mkfile $(MAKE_GOALS) $(EXTRA_MAKE_GOALS) ($(TARGET) $(BUILD_TYPE))$(COLOUR_RST)"; \
		fi; \
		$(RM) .build_prerequisites; \
		$(MAKE) -f $$mkfile $(MAKE_GOALS) $(EXTRA_MAKE_GOALS) PATH="$(PATH)" $(SILENT_MAKE); \
		if [[ $$? -ne 0 ]] ; then \
			$(ECHO) "$(COLOUR_ERR)$$mkfile - failed$(COLOUR_RST)"; \
			exit 1; \
		else \
			if [[ "$(FLAGS_VERBOSE)" != "" ]] ; then \
				$(ECHO) "$(COLOUR_MAK)$$mkfile - finished $(COLOUR_RST)" ; \
			fi; \
		fi; \
	done
	@if [[ "$(FLAGS_SILENT)" != "true" ]] ; then $(ECHO) "$(COLOUR_AOK)$${PWD##*/} build succesfully completed$(COLOUR_RST)" ; fi ;

# Clean everything for the specific target (inc sub-make dirs)
.PHONY: clean
clean: MAKE_GOALS += clean
clean: _run_make

# Clean everything for all targets (inc sub-make dirs)
.PHONY: cleanall
cleanall: MAKE_GOALS += cleanall
cleanall: _run_make

# Call test without any parameters - use defaults
.PHONY: test
test: _run_make

# If you call print or print_<var> directly here - use the default target (x86Linux)
.PHONY: print
print: target_x86Linux
print: MAKE_GOALS += print
print: _run_make

# Print single variable
.PHONY: print_%
print_%:
	@$(MAKE) -f makefile.mk $@ PATH="$(PATH)" $(SILENT_MAKE)

# print single variable with each item on new line
.PHONY: printf_%
printf_%:
	@$(MAKE) -f makefile.mk $@ PATH="$(PATH)" $(SILENT_MAKE) | tr ' ' '\n'

############### Stand-alone commands ################
# These are meant to be run as stand-alone commands, for example if you want to set the LD_LIBRARY_PATH
# You could do:
#	> make set_ld_lib_path
# However you can also use these functions with specific targets, so if you wanted to set the LD_LIBRARY_PATH
# for x64Linux you would do:
#	> make target_x64Linux set_ld_lib_path

# Rule to set the ld library path
ifneq (,$(findstring set_ld_lib_path,$(ALL_PARAMS)))
  FLAGS_SILENT = true
  MAKE_GOALS += set_ld_lib_path
endif
.PHONY: set_ld_lib_path
set_ld_lib_path: _run_make

# Rule to run the gcov command
ifneq (,$(findstring run_gcov_cmd,$(ALL_PARAMS)))
  FLAGS_SILENT = true
  MAKE_GOALS += run_gcov_cmd
  FLAGS_ANALYSE = analyse
endif
.PHONY: run_gcov_cmd
run_gcov_cmd: _run_make

############### Build Modifiers ################

# IMPORTANT NOTE
# These are meant to be called as secondary build goals since they only modify the
# flags that are passed to the makefile.mk. However if they are the first parameter
# They become THE rule, so we add a rule here to do the default build, but also
# it does the tab completion

# Release build
.PHONY: release
release: FLAGS_TARGET += -O2
release: _run_make

# Debug build
.PHONY: debug
debug: FLAGS_TARGET += -g
debug: _run_make

# precompiled header build
.PHONY: precompiled_header
precompiled_header: _run_make

# verbose
.PHONY: verbose
verbose: _run_make

# very verbose  (vverbose)
.PHONY: vverbose
vverbose: _run_make

# analyse
.PHONY: analyse
analyse: _run_make

################# The Targets #################

# IMPORTANT NOTE
# These are not really meant to be called directly because they simply call make with no parameters.
# In realailty this is the same as calling make build since "build" is the default parameter at the
# moment, but that means it works by luck more then design - e.g. the default goal coult change.

# Linux x86 c++ compiler
.PHONY: target_x86Linux
#target_x86Linux: TARGET := x86Linux
#target_x86Linux: CC := gcc
#target_x86Linux: CXX := g++
#target_x86Linux: RANLIB := ranlib
#target_x86Linux: AR := ar
#target_x86Linux: PATH := $(PATH)
#target_x86Linux: FLAGS_TARGET := -m32
#target_x86Linux: MAKE_GOALS +=
#target_x86Linux: $(BUILD_TYPE)
target_x86Linux: _run_make

# Linux x64 c++ compiler
.PHONY: target_x64Linux
#target_x64Linux: TARGET := x64Linux
#target_x64Linux: CC := gcc
#target_x64Linux: CXX := g++
#target_x64Linux: RANLIB := ranlib
#target_x64Linux: AR := ar
#target_x64Linux: PATH := $(PATH)
#target_x64Linux: FLAGS_TARGET := -m64
#target_x64Linux: MAKE_GOALS +=
#target_x64Linux: $(BUILD_TYPE)
target_x64Linux: _run_make

## target_iMX8EVK	: build the applications for the armv8 NXP i.MX8 EVK dev board
.PHONY: target_iMX8EVK
target_iMX8EVK: TARGET := iMX8EVK
target_iMX8EVK: CC := aarch64-poky-linux-gcc
target_iMX8EVK: CXX := aarch64-poky-linux-g++
target_iMX8EVK: RANLIB := aarch64-poky-linux-gnueabi-ranlib
target_iMX8EVK: AR := aarch64-poky-linux-gnueabi-ar
target_iMX8EVK: PATH := /opt/fsl-imx-x11/4.9.51-mx8-beta/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux:$(PATH)
target_iMX8EVK: FLAGS_TARGET := -march=armv8-a -mtune=cortex-a53 --sysroot=/opt/fsl-imx-x11/4.9.51-mx8-beta/sysroots/aarch64-poky-linux
target_iMX8EVK: MAKE_GOALS +=
target_iMX8EVK: $(BUILD_TYPE)
target_iMX8EVK: _run_make

## target_6GHzRx	: build the applications for the armv7 i.MX6 6GHzRx
.PHONY: target_6GHzRx
target_6GHzRx: TARGET := 6GHzRx
target_6GHzRx: CC := arm-poky-linux-gnueabi-gcc
target_6GHzRx: CXX := arm-poky-linux-gnueabi-g++
target_6GHzRx: RANLIB := arm-poky-linux-gnueabi-ranlib
target_6GHzRx: AR := arm-poky-linux-gnueabi-ar
target_6GHzRx: PATH := /opt/fsl-imx-x11/4.1.15-1.1.1/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi:$(PATH)
target_6GHzRx: FLAGS_TARGET := -march=armv7-a -mfloat-abi=hard -mfpu=neon -mtune=cortex-a9 --sysroot=/opt/fsl-imx-x11/4.1.15-1.1.1/sysroots/cortexa9hf-vfp-neon-poky-linux-gnueabi
target_6GHzRx: MAKE_GOALS +=
target_6GHzRx: $(BUILD_TYPE)
target_6GHzRx: _run_make

## target_6GHzTx	: build the applications for the armv7 i.MX6 6GHzTx
.PHONY: target_6GHzTx
target_6GHzTx: TARGET := 6GHzTx
target_6GHzTx: CC := arm-poky-linux-gnueabi-gcc
target_6GHzTx: CXX := arm-poky-linux-gnueabi-g++
target_6GHzTx: RANLIB := arm-poky-linux-gnueabi-ranlib
target_6GHzTx: AR := arm-poky-linux-gnueabi-ar
target_6GHzTx: PATH := /opt/trl-imx-6GTcvr/4.1.15-1.2.0/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi:$(PATH)
target_6GHzTx: FLAGS_TARGET := -march=armv7-a -mfloat-abi=hard -mfpu=neon -mtune=cortex-a9 --sysroot=/opt/trl-imx-6GTcvr/4.1.15-1.2.0/sysroots/cortexa9hf-vfp-neon-poky-linux-gnueabi
target_6GHzTx: MAKE_GOALS +=
target_6GHzTx: $(BUILD_TYPE)
target_6GHzTx: _run_make
