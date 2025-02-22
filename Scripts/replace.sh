#!/usr/bin/env sh

################################################################################
echo "👉\tReplace characters in \"$1\""

################################################################################
## Variables
################################################################################

# Get current date in format DD.MM.YYYY
document_date=$(date +%d.%m.%Y)

# Get latest git tag
document_git_tag=$(git describe --tags --abbrev=0)


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

# Document date
$sedcmd "s/REPLACE_DATE/$document_date/g" $1

# Document version
$sedcmd "s/REPLACE_VERSION/v$CI_COMMIT_REF_NAME/g" $1

# Replace path to images
$sedcmd 's/Media/Content\/Media/g' $1

# Replace NAME and escape spaces
$sedcmd "s/REPLACE_NAME/$(echo $NAME | sed 's/ /\\ /g')/g" $1

# Replace USERNAME
$sedcmd "s/REPLACE_USERNAME/$USERNAME/g" $1

# Add "\pagebreak" before each heading 1
$sedcmd 's/^# /\\pagebreak\n# /g' $1