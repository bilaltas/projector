#!/bin/bash

# Max 256
for ((i=2;i<50;i++))
do
    sudo ifconfig lo0 alias 127.0.0.$i up
done