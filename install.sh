#!/bin/bash


# Get the functions
source global.sh



echo "PROJECTOR installing..."
cp projector-bin /usr/local/bin/projector
sedreplace "s#BUILDERDIR=builderdir#BUILDERDIR=$BASEDIR#g" /usr/local/bin/projector;
echo -e "${GREEN}PROJECTOR HAS BEEN INSTALLED${RESET}"
echo -e "You can now use '${BLUE}projector${RESET}' command in your 'Projects' folder."
