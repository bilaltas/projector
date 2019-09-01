#!/bin/bash

#if [[ ! -f /bin/wp-cli.phar ]]; then

	apt-get update -qq
	apt-get install -qq -y sudo less mariadb-client
	rm -rf /var/lib/apt/lists/*

#fi