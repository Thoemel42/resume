#!/usr/bin/env sh

################################################################################
## Variables
################################################################################

################################################################################
## Environment specific replacements commands
################################################################################

if [ $CI ]; then
	sedcmd="sed -i"
else
	sedcmd="sed -i ''"
fi


################################################################################
## REPLACERS
################################################################################

# Add "\pagebreak" before each heading 1
function addPageBreaks() {
    echo $(cat)
    $sedcmd 's/^# /\\pagebreak\n# AAA/g' $1
}
