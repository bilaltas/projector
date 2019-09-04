#!/bin/bash

# apt-get update -qq &> /dev/null
# apt-get install -qq -y sudo less mariadb-client &> /dev/null
# rm -rf /var/lib/apt/lists/*

# curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
# chmod +x /usr/local/bin/wp


docker_compose apt-get update -qq
docker_compose apt-get install -qq -y sudo less mariadb-client
docker_compose rm -rf /var/lib/apt/lists/*

docker_compose curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker_compose chmod +x /usr/local/bin/wp