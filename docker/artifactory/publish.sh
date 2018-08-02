#!/bin/sh

export ARTIFACTORY_VERSION=6.1.0
export ARTIFACTORY_REVISION=1

docker tag nextbreakpoint/artifactory:$ARTIFACTORY_VERSION nextbreakpoint/artifactory:$ARTIFACTORY_VERSION-$ARTIFACTORY_REVISION && docker push nextbreakpoint/artifactory:$ARTIFACTORY_VERSION-$ARTIFACTORY_REVISION
