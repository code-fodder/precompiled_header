# Generate sources list for cpp, cxx and c files
SOURCES = $(foreach dir,$(SOURCE_DIRS),$(wildcard $(dir)/*.cpp $(dir)/*.cxx $(dir)/*.c))

# Generate headers list for hpp, hxx and h files
HEADERS = \
	$(foreach dir,$(INC_DIRS),$(wildcard $(dir)/*.hpp $(dir)/*.hxx $(dir)/*.h $(dir)/*.hh)) \
	$(foreach dir,$(SYS_INC_DIRS),$(wildcard $(dir)/*.hpp $(dir)/*.hxx $(dir)/*.h $(dir)/*.hh)) \

# Generate includ dirs list
INC_PATHS = \
	$(addprefix -I,$(INC_DIRS)) \
	$(addprefix -isystem,$(SYS_INC_DIRS)) \

# Generate objects list from the sources list prefixed with the object dir
OBJECTS = $(addprefix $(OBJECT_DIR)/,$(addsuffix .o,$(basename $(patsubst %,%,$(SOURCES)))))

# Generate dependency files list. The compiler creates these (-MMD flag) same as obj file with a .d extension
DEPS = $(subst $(OBJECT_DIR),$(DEP_DIR),$(OBJECTS:%.o=%.d)) $(PCH_FILE_DEP)

# Precompiled header flags
### Precompiled header flags
ifneq (,$(findstring true,$(USE_PRECOMPILED_HEADER)))
  $(info ------------------------------------> using precompiled header <------------------------------------)
  PCH_FILE = pch_$(TARGET)$(BUILD_TYPE).hpp
  PCH_FILE_OBJ = $(PCH_FILE).gch
  PCH_FILE_DEP = $(PCH_FILE_OBJ).d
  FLAGS_PCH = -Winvalid-pch -include $(PCH_FILE)
endif

# Comiler flags
CFLAGS += $(INC_PATHS) $(GCOV_FLAGS)
CXXFLAGS += $(INC_PATHS) $(CXX_STD) $(GCOV_FLAGS)

# Generate the output directories list (used for creating/cleaning output dirs
OUTPUT_DIRS = \
	$(OUTPUT_DIR) \
	$(OBJECT_DIR) \
	$(addprefix $(OBJECT_DIR)/,$(SOURCE_DIRS)) \
	$(DEP_DIR) \
	$(addprefix $(DEP_DIR)/,$(SOURCE_DIRS))

# Create the library linker options for the linker (-L<path> and -l<lib>)
# First add the super repo prefix if it exists
ifdef SUPER_REPO_PATH
  LIB_DEPS_TMP = $(addprefix $(realpath $(SUPER_REPO_PATH))/,$(LIB_DEPS))
else
  LIB_DEPS_TMP = $(LIB_DEPS)
endif
LIBRARY_LINK_FILES_TMP = $(notdir $(LIB_DEPS_TMP))
LIB_LINK_FLAGS = \
	$(addprefix -L,$(dir $(LIB_DEPS_TMP))) \
	$(addprefix -l,$(basename $(LIBRARY_LINK_FILES_TMP:lib%=%))) \
	$(STANDARD_LIBS)

LINK_CMD = $(CC) $(LFLAGS) $(OBJECTS) -o $(OUTPUT_DIR)/$(OUTPUT_FILE) $(LIB_LINK_FLAGS)

# Add the super repo prefix if it exists
ifdef SUPER_REPO_PATH
  DEP_MAKE_DIRS_TMP := $(DEP_MAKE_DIRS)
  DEP_MAKE_DIRS = $(addprefix $(realpath $(SUPER_REPO_PATH))/,$(DEP_MAKE_DIRS_TMP))
endif

# This contains the full paths required to link to the libraries
LD_LIBRARY_PATH_VAL = $(subst $(eval) ,:,$(realpath $(dir $(LIB_DEPS_TMP))))

# Clean items will clean all the items for one specific target - e.g. running "make target_x64Linux release clean" will just clean the file for
# the x86Linux release build
CLEAN_ITEMS = $(BIN_DIR)/*$(TARGET)$(BUILD_SUFFIX)* \
              $(LIB_DIR)/*$(TARGET)$(BUILD_SUFFIX)* \
              $(OBJECT_DIR) \
			  $(addprefix $(OBJECT_DIR)/,$(SOURCE_DIRS)) \
			  $(DEP_DIR) \
			  $(addprefix $(DEP_DIR)/,$(SOURCE_DIRS)) \
			  coverage.xml \
			  memcheck.xml memcheck.out \
			  .build_prerequisites

# Derive this from the CLEAN_ITEMS by taking the base dir of each since we are going to remove the entire dir:
# $(subst /, ,$(p)) : substitutes all / by space in the expansion of make variable p
# firstword         : keeps only the first word of the result, that is the first folder you are interested in
# foreach           : iterates over the words of VAR and sets make variable p to the current word
# sort              : removes duplicates (and... sorts).
CLEANALL_ITEMS = $(sort $(foreach p,$(CLEAN_ITEMS),$(firstword $(subst /, ,$(p)))))
#CLEANALL_ITEMS = obj dep bin lib

# Flags to pass to the submakefile
FLAGS_SUB_MAKEFILE = $(FLAGS_VERBOSE) $(FLAGS_ANALYSE)


######################
### Analysis tools ###

# Set the analyse flag to false if this is thirdparty code
ifneq (,$(findstring true,$(FLAGS_DONT_ANALYSE)))
  FLAGS_ANALYSE =
endif

### CCP CHECK ###
# Generate includ dirs list
CPPCHECK_INC_PATHS = \
	$(addprefix -I,$(INC_DIRS)) \
	--config-exclude=dds

# Always suppress anything in the system includes list
CPPCHECK_FILTERS += $(SYS_INC_DIRS)

# Put together the cpp check command line
CPPCHECK_CMD_LINE = $(CPPCHECK) $(CPPCHECK_INC_PATHS) $(CPPCHECK_FLAGS) $(CPPCHECK_SUPRESSIONS) $(CPPCHECK_FORMAT) $(RULE_DEPENDENCY)

# If analyse is set true then perform cppcheck
ifneq (,$(findstring analyse,$(FLAGS_ANALYSE)))
# Create the CPPCHECK command. This command works by:
# 1. Check if the words in the filter list match the current dependency (e.g. is 'autogen' in the object file path?).
#    If a match is found then don't cpp check this file
# 2. If we are running cppcheck then run the command in a bash subshell like this: $(...cmd...), however we need to
#    escape make '$' so we use $$(...) (same for bash variables: $$bash_var).
# 3. When running the cpp check command it is the stderr we want. So route stderr to stdout (2>&1), then route stdout
#    to null (... > /dev/null).
# 4. Store the output of the cpp check command (thd stderr) in a bash var called cpp_res. Then print it line by line
#    prefixing with the current dir to get the full file path (this helps IDEs and us to find the file).
  CPPCHECK_BASH_CMD = \
	do_cpp_check=yes ; \
	for CPPCHECK_FILTER in $(CPPCHECK_FILTERS) ; do \
		if [[ $(RULE_DEPENDENCY) ==  *"$$CPPCHECK_FILTER"* ]] ;  then do_cpp_check=no ; fi ; \
	done ; \
	if [[ "$$do_cpp_check" == "yes" ]] ; then \
		$(ECHO) "$(COLOUR_ACT)ccpcheck: $(RULE_DEPENDENCY)$(COLOUR_RST)" ; \
		cpp_res="$$($(CPPCHECK_CMD_LINE) 2>&1 > /dev/null)" ; \
		cpp_err="false" ; \
		while read -r err_line ; do \
			if [[ "$$err_line" != "" ]] ; then $(ECHO) "$(COLOUR_ERR)$(CURDIR)/$$err_line$(COLOUR_RST)" ; cpp_err="true" ; fi ; \
		done <<< $$cpp_res ; \
		if [ "$$cpp_err" == "true" ] && [ "$(CPPCHECK_WERROR)" == "true" ] ; then exit 1 ; fi ; \
	fi ;
else
  CPPCHECK_BASH_CMD =
endif

### GCOV ###
# If analyse is set true then use gcov flags
ifneq (,$(findstring analyse,$(FLAGS_ANALYSE)))
  # set these IF using gcov
  # Always suppress anything in the system includes list
  GCOV_FILTERS += $(SYS_INC_DIRS)
  # Use -fprofile-arcs generates .gcno at compile time, -ftest-coverage generates run-time output in .gcda files
  GCOV_FLAGS = -fprofile-arcs -ftest-coverage
  # Directory extension for using gcov (i.e. where the objects go)
  GCOV_OBJ_DIR = /gcov
  # Add coverage linker flags
  LFLAGS += -lgcov --coverage
  # The command to run gcovr
  GCOV_CMD = $(GCOVR) $(OBJECT_DIR) $(addprefix -e ,$(GCOV_FILTERS)) -s --xml -o coverage.xml
endif
