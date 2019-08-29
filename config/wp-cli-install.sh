#!/bin/bash

if [[ ! -f /bin/wp-cli.phar ]]; then

	apt-get update -qq
	apt-get install -qq -y sudo less mariadb-client
	rm -rf /var/lib/apt/lists/*

	curl -sS -o /bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x /bin/wp-cli.phar

fi