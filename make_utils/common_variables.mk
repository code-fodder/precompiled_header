include make_utils/globals.mk
include make_utils/common_colours.mk

# For printing. This takes a copy of all the environment variables. We take
# this copy before we set any variables so that we can filter those variables
# out later and just print the new variables we have set.
VARS_OLD := $(.VARIABLES)
VARS_OLD := $(filter-out TARGET CC CXX RANLIB AR PATH FLAGS_TARGET LIB_DEPS BUILD_SUFFIX,$(VARS_OLD))

# This can be useful for setting the LD LIBRARY PATH easily
LD_LIBRARY_PATH_VAL =

# Post build tasks - this is meant to contain some simple bash instructions like copying files required
# to run the application. Its not really intended for complicated scripts becuase:
#    1. Its difficult to read
#    2. Its difficult to debug.
# However nothig is stopping you from using it that way. But it would be better to just create a script
# called post_build_tasks.sh and call that.
# Note each line must end with a semi-colon ';'.
POST_BUILD_TASKS =

# Same as post build, but occurs before the build starts
PRE_BUILD_TASKS =

# This is really just a reminder. Can use these variables as required.
# Rule format is  "$@: $<"
RULE_TARGET = $@
RULE_DEPENDENCY = $<
RULE_DEPENDENCIES = $^

### Build Configuation ###
# Passed in build variables they are just here for reference really - they are already set.
TARGET ?=
BUILD_TYPE ?=
CC ?=
CXX ?=
RANLIB ?=
AR ?=
PATH ?=
FLAGS_TARGET ?=
USE_PRECOMPILED_HEADER ?=
# The -s flag silences makes changing dir / nothing to be done, etc... info messages.
# this can be overriddden with the verbose flag
SILENT_MAKE ?=
# Set to verbose or vverbose for more debug (or emtpy for normal level)
FLAGS_VERBOSE ?=
# Set to analyse if extra analysis is required
FLAGS_ANALYSE ?=
# Added extra flags to this variable to pass down to sub makfiles (like "verbose, analyse, etc...")
FLAGS_SUB_MAKEFILE =

### Precompiled header flags
PCH_HEADER = pch.hpp
PCH_FILE =
PCH_FILE_OBJ =
PCH_FILE_DEP =
FLAGS_PCH =

### Build flags
CFLAGS = $(FLAGS_TARGET)
CXXFLAGS = $(FLAGS_TARGET)
LFLAGS = $(FLAGS_TARGET)
DEFINES =

### C/C++ standards ###
CXX_STD = -std=c++11

### Commands ###
MAKE_DIR = mkdir -p
RM = rm -rf

### Super Repo Support ###
# If this is set then the project should expect to find DEP_MAKE_DIRS and LIB_DEPS with the prefix of SUPER_REPO_PATH.
SUPER_REPO_PATH =

### Inputs ###
# Source directories
SOURCE_DIRS = .
# Source files (can be manually added or allow var_expansions to find then for you)
SOURCES =
# Paths where required headers files are found
INC_DIRS = .
# Paths of header files from other projects that we dont want warnings for (-isystem instead of -I)
SYS_INC_DIRS =
# Header files (not sure if this will be used/needed for anything - useful for printing/debugging)
HEADERS =
# List of paths to include (-I<path>) used by the compiler
INC_PATHS =

### Dependencies ###
# Lib flags for linking
LIB_LINK_FLAGS =
# These are folders which contain makefile that this project depends on building first
DEP_MAKE_DIRS =
# This is the make goal to pass to the dependency make project dir
DEP_MAKE_GOAL =
# Libs deps contains the library linker-command options (-Lpaths and -llib names)
LIB_DEPS =
# The common standard libraries
STANDARD_LIBS = -lstdc++ -lpthread -lrt

### Outputs ###
# The name of the generated executable/library is dependant on this
PROJECT_NAME = out
# Full path of the project
PROJET_DIR = $(CURDIR)
# Location where the object files are put
OBJECT_DIR = obj/$(TARGET)_$(BUILD_TYPE)$(GCOV_OBJ_DIR)
# List of object files
OBJECTS =
# Location where the object deps (obj.d) files are put
DEP_DIR = dep/$(TARGET)_$(BUILD_TYPE)
# Object specific dependencies (obj.d files)
DEPS =
# Location where binary/executable output files are put
BIN_DIR = bin
# Location where the libary files are put
LIB_DIR = lib
# The output directory - this is set to BIN_DIR or LIB_DIR depending on the type of output required, can be set manually or by calling
# common_executable.mk or common_shared_lib.mk
OUTPUT_DIR = $(BIN_DIR)
# project name should be set in makefile*.mk. It can be modified into OUTPUT_FILE depending on output type (e.g. library) and
# build type (release/debug)
OUTPUT_FILE = $(PROJECT_NAME)
# Items to clean for the currecnt specific target
CLEAN_ITEMS =
# Items to clean for all targets
CLEANALL_ITEMS =

### Warnings ###
# Warning flags used by the C compiler
FLAGS_C_WARNINGS =
# Warning flags used by the C++ compiler
FLAGS_CPP_WARNINGS =
# Base levels
FLAGS_WARNINGS_BASE =
FLAGS_WARNINGS_CPP_BASE =
FLAGS_WARNINGS_C_BASE =
# Selectable levels
FLAGS_WARNINGS_CPP_HOST =
FLAGS_WARNINGS_CPP_TARGET =
FLAGS_WARNINGS_C_HOST =
FLAGS_WARNINGS_C_TARGET =
FLAGS_WARNINGS_DISABLED =

# Dont analyse flag - set to true if the project is 3rd party or test code so that warnings and other checks will not be applied
FLAGS_DONT_ANALYSE = false

### cppcheck ###
# cppcheck command
CPPCHECK = cppcheck
# Flags to use with cppcheck
CPPCHECK_FLAGS =  --enable=all --inconclusive --force
# Suppress unwanted cppcheck messages
CPPCHECK_SUPRESSIONS = --suppress=unmatchedSuppression --suppress=missingInclude --suppress=unusedFunction
# The output format of the errors, other formats include: --template=vs, --xml-version=2
CPPCHECK_FORMAT = --template=gcc
# Filter to apply to cppcheck. If the object build compiled contains one or more string in this filter list
# then it is not cppcheck'd
CPPCHECK_FILTERS =
# The paths for cppcheck to look in for headers (not to be set to any system paths)
CPPCHECK_INC_PATHS =
# Command line to call cppcheck on a single file
CPPCHECK_CMD_LINE =
# cpp check bash command line - this contains a micro-script to run ccpcheck. It is responsible to filter
# out files that are not to be checked and prcesses the output.
CPPCHECK_BASH_CMD =
# Treat cppcheck issues as errors
# @todo lets set this to true at some point, then there is no need jenkins xml output - just like compiler warnings.
# For the moment in jenkins we can overule this with:
#	make ... CPPCHECK_WERROR="true"
CPPCHECK_WERROR = false

### gcov (code coverage) ###
# gcovr command
GCOVR = gcovr
# gcov flags.
GCOV_FLAGS =
# Directory extension for using gcov (i.e. where the objects go)
GCOV_OBJ_DIR =
# GCOV filters (-e <path-to-source> excludes folders, -f <path-to-source> folders must match
GCOV_FILTERS =

### valgrind ###
# Valgrind memcheck with just the xml output
#VALGRIND_MEMCHK_CMD = valgrind --tool=memcheck --leak-check=full --xml=yes --xml-file=$(PROJET_DIR)/memcheck.xml
# With logging recorded to file
VALGRIND_MEMCHK_CMD = valgrind --tool=memcheck --leak-check=full --xml=yes --xml-file=$(PROJET_DIR)/memcheck.xml --verbose 2> $(PROJET_DIR)/memcheck.logging
