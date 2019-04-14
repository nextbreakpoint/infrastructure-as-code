!#/bin/sh

export SCALA_VERSION=2.11
export FLINK_VERSION=1.7.2
export IMAGE_REVISION=1

docker build -t nextbreakpoint/flink:${FLINK_VERSION}-${IMAGE_REVISION} --build-arg flink_version=${FLINK_VERSION} --build-arg scala_version=${SCALA_VERSION} . && docker push nextbreakpoint/flink:${FLINK_VERSION}-${IMAGE_REVISION}
