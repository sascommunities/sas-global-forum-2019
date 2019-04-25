#! /bin/bash

FOLDER=$1
IMAGE=$2

CONTAINER=`docker run -d --rm -p 8888:8888 \
           --name viya_$IMAGE \
           -v $FOLDER/notebooks/:/home/ds/notebooks \
           -v $FOLDER/data/:/home/ds/datasets \
           -v $FOLDER/logs/:/home/ds/logs \
           -v $FOLDER/custom/:/home/ds/custom \
           centos-ds/$IMAGE`
echo $CONTAINER
