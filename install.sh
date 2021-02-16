#!/bin/bash


# Get the functions
source global.sh


echo "PROJECTOR installing..."


# Copy the binary file
sudo cp ./projector-bin /usr/local/bin/projector
sudo chmod +rwx /usr/local/bin/projector
file_search_replace "s#BUILDERDIR=builderdir#BUILDERDIR=\"$BASEDIR\"#g" "/usr/local/bin/projector"


echo -e "${GREEN}PROJECTOR HAS BEEN INSTALLED${RESET}"
echo -e "You can now use '${BLUE}projector${RESET}' command in your 'Projects' folder."