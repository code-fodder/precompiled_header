# -Wall                  provides all construction warnings
# -Wextra                adds a few extra warnings on top of Wall, e.g. unused parameter
# -Wpedantic             warns about non ISO C/C++ compliance and gives an error
# -W(sign-)conversion    warns about implicit conversions that may change a value.
# -Wunreachable-code     warns about unreachable code paths
# -Wduplicated-cond      warns about duplicated if/elseif conditions
# -Wduplicated-branches  warns about if/else sections that are identical (copy/paste errors?)
# -Wlogical-op           warns about use of logical operations where bitwise where probably intended
# -Wnull-dereference     warns about code paths that could dereference a null pointer
# -Wuseless-cast         warns about casting to its own type (probably a typeo by user)
# -Wshadow               warns about local variables with the same name as globals
# -Werror          NOTE: turns all warnings in to errors

# Note: the warning unused-result may come into play in release builds. It means return value of a function
#       has not been dealt with. We should fix these warnings, but just in case we need to we can suppress
#       it with -Wno-unused-result

# The most basic set of warnings that everything should support
FLAGS_WARNINGS_BASE = \
	-Wall \
	-Wextra \
	-Wpedantic \
	-Wconversion \
	-Wsign-conversion \
	-Wunreachable-code  \
	-Wlogical-op  \
	-Wshadow \
	-Wmissing-include-dirs \
	-Wparentheses \
	-Werror

# All c++ compilers should support these warnings
FLAGS_WARNINGS_CPP_BASE = \
	$(FLAGS_WARNINGS_BASE) \
	-Wuseless-cast

# All c compilers should support these warnings
FLAGS_WARNINGS_C_BASE = \
	$(FLAGS_WARNINGS_BASE)

########################################################
# A compiler should use one of the following           #
########################################################
# C++ Warning levels - HOST
FLAGS_WARNINGS_CPP_HOST      = $(FLAGS_WARNINGS_CPP_BASE) \
                               -Wduplicated-cond \
							   -Wnull-dereference

# C++ Warning levels - TARGET
FLAGS_WARNINGS_CPP_TARGET    = $(FLAGS_WARNINGS_CPP_BASE)

# C Warning levels - HOST
FLAGS_WARNINGS_C_HOST        = $(FLAGS_WARNINGS_C_BASE) \
                               -Wduplicated-cond \
							   -Wnull-dereference

# C Warning levels - TARGET
FLAGS_WARNINGS_C_TARGET      = $(FLAGS_WARNINGS_C_BASE)

# Disable warnings e.g. for third party code
FLAGS_WARNINGS_DISABLED   = -w

########################################################
# Setup the warning level based on target              #
########################################################
ifneq (,$(findstring false,$(FLAGS_DONT_ANALYSE)))
	ifneq (,$(findstring Linux,$(TARGET)))
#        $(info WARNING LEVEL: Host)
		FLAGS_CPP_WARNINGS = $(FLAGS_WARNINGS_CPP_HOST)
		FLAGS_C_WARNINGS   = $(FLAGS_WARNINGS_C_HOST)
	else
#        $(info WARNING LEVEL: Target)
		FLAGS_CPP_WARNINGS = $(FLAGS_WARNINGS_CPP_TARGET)
		FLAGS_C_WARNINGS   = $(FLAGS_WARNINGS_C_TARGET)
	endif
else
#    $(info WARNING LEVEL: Disabled)
	FLAGS_CPP_WARNINGS = $(FLAGS_WARNINGS_DISABLED)
	FLAGS_C_WARNINGS   = $(FLAGS_WARNINGS_DISABLED)
endif