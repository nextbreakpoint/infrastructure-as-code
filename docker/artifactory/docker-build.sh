#!/bin/sh

export ARTIFACTORY_VERSION=6.1.0

docker build -t nextbreakpoint/artifactory:$ARTIFACTORY_VERSION --build-arg artifactory_version=$ARTIFACTORY_VERSION $(pwd)/artifactory
