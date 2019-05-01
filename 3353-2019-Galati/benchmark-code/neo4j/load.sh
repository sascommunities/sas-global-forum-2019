#!/bin/bash

FOLDER=$1           # Folder containing the csv files to load
FOLDER=${FOLDER%/}  # remove trailing slash if exists

../bin/neo4j-admin import --database=${FOLDER}.db --nodes=${FOLDER}/nodes_header.csv,${FOLDER}/nodes.csv --relationships=${FOLDER}/links_header.csv,${FOLDER}/links.csv > import.log 2>&1

mv import.report $FOLDER
mv import.log $FOLDER
