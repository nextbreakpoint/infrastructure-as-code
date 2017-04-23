#!/usr/bin/env bash
set -e

echo "Fetching Kafka..."
cd /tmp
sudo curl -L -o kafka.tgz http://mirror.vorboss.net/apache/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

echo "Installing Kafka..."
sudo tar -C /opt -xvzf kafka.tgz

sudo useradd kafka -m
sudo echo -e 'kafka\nkafka' | sudo passwd kafka

sudo rm kafka.tgz

sudo chown kafka:kafka -R /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}
