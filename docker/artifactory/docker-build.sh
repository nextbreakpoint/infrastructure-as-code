#!/bin/sh

export ARTIFACTORY_VERSION=5.4.6

docker build -t nextbreakpoint/artifactory:$ARTIFACTORY_VERSION --build-arg artifactory_version=$ARTIFACTORY_VERSION $(pwd)/artifactory
