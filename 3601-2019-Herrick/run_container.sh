#! /bin/bash

FOLDER=$1
IMAGE=$2

CONTAINER=`docker run -d --rm -p 8888:8888 -v $FOLDER:/home/ds/notebooks centos-ds/$IMAGE`
echo $CONTAINER
