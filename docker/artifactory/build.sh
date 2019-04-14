#!/bin/sh

export ARTIFACTORY_VERSION=6.1.0
export IMAGE_REVISION=1

docker build -t nextbreakpoint/artifactory:${ARTIFACTORY_VERSION}-${IMAGE_REVISION} --build-arg artifactory_version=${ARTIFACTORY_VERSION} . && docker push nextbreakpoint/artifactory:${ARTIFACTORY_VERSION}-${IMAGE_REVISION}
