#colours for aesthetics
RED    = \033[1;31m
GREEN  = \033[1;32m
YELLOW = \033[1;33m
BLUE   = \033[1;34m
CYAN   = \033[1;36m
NC     = \033[m

# Used for highlighting issues (failed tests etc...)
COLOUR_ERR = $(RED)
# Used for highlighting complete goals/targets
COLOUR_AOK = $(GREEN)
# Used to highlight work (compiling, linking, etc...)
COLOUR_ACT = $(BLUE)
# Used to highlight dependeny information (like which dep is being processed)
COLOUR_DEP = $(YELLOW)
# Used to highlight folder changes and make goals
COLOUR_MAK = $(CYAN)
# Resets the colour
COLOUR_RST = $(NC)

