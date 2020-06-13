# Util functions to return the root makefile name and the current makefile name
#GET_THIS_MAKEFILE = $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
GET_THIS_MAKEFILE   = $(CURDIR)/$(lastword $(MAKEFILE_LIST))
GET_ROOT_MAKEFILE   = $(firstword $(MAKEFILE_LIST))
GET_ROOT_MAKEFILE_BASENAME  = $(shell basename $(GET_ROOT_MAKEFILE))
GET_MAKE_SUFFIX     = $(findstring _test,$(GET_ROOT_MAKEFILE_BASENAME))
GET_CURDIR_BASENAME         = $(shell basename $(CURDIR))

### These are here because they are used by all ###
# Use bash (other wise the default is /bin/sh... which is limited)
SHELL = /bin/bash
# Echo command (with colour)
ECHO = echo -e 
# print command
PRINT = printf
