#!/usr/bin/env bash

#
# Regular Expression library
#

# -- For sed --
# Finds and removes inline comments
SED_PATTERN_INLINE_COMMENT='s/\s*#.*//'
# Finds and deletes lines that are empty
SED_PATTERN_DELETE_EMPTY_LINES='/^\s*$/d'
# Extracts a variable name from the output of 'declare -p'
SED_PATTERN_EXTRACT_VAR_NAME='s/declare -- \([^=]*\)=.*/\1/p'

# -- For grep --
# Finds lines that are full comments or empty (for use with grep -vE)
GREP_PATTERN_COMMENT_OR_EMPTY='^\s*#|^\s*$'
# Finds variable names matching the NODE_..._ALIAS pattern
GREP_PATTERN_NODE_ALIAS_VAR='^NODE_.*_ALIAS$'
