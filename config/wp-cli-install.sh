#!/bin/bash

apt-get update -qq &> /dev/null
apt-get install -qq -y sudo less mariadb-client &> /dev/null
rm -rf /var/lib/apt/lists/*