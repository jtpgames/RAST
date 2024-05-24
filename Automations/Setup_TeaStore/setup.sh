#!/bin/bash

# move to root folder
cd ../../

cd TeaStore
mvn clean install -DskipTests

cd tools/
./build_docker.sh
