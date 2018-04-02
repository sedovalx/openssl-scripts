#!/usr/bin/env bash

BLUE='\033[0;34m'
NC='\033[0m' # No Color

read -r -d '' MESSAGE << EOM
The command supports next arguments:
 - *required* the name of the target folder where the CA should be created (the name is added to the current dir)
 - *optional* names of the intermediate certificates, comma separated
EOM

: ${1?"$MESSAGE"}
if [ -z "$1" ]; then
	echo "$MESSAGE"
	exit 1
fi

CA_DIR=$PWD/$1
PARAMS=("$@")
INTERM_DIR_NAMES=("${PARAMS[@]:1}")

INTERM_DIRS=()

for name in "${INTERM_DIR_NAMES[@]}"
do
	PARTS=(${name//\// })
	if [ ${#PARTS[@]} -gt 1 ]
	then
		TEMP=$CA_DIR
		for part in "${PARTS[@]}"
		do 
			TEMP="$TEMP/$part"
			INTERM_DIRS+=("$TEMP")
		done
		unset TEMP
	else 
		INTERM_DIRS+=("$CA_DIR/$name")
	fi
done

unset INTERM_DIR_NAMES

echo -e "The next folder structure is about to be created."
echo -e "${BLUE}The root CA folder:${NC}"
echo $CA_DIR
echo -e "${BLUE}The intermediate certificate folders:${NC}"
for name in "${INTERM_DIRS[@]}"
do
	echo $name
done

