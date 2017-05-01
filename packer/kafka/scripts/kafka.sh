#!/usr/bin/env bash
set -e

echo "Fetching Kafka..."
sudo curl -L -o /tmp/kafka.tgz http://mirror.vorboss.net/apache/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

echo "Installing Kafka..."
sudo tar -C /opt -xvzf /tmp/kafka.tgz
sudo rm /tmp/kafka.tgz

sudo useradd kafka -m
sudo echo -e 'kafka\nkafka' | sudo passwd kafka

sudo chown kafka:kafka -R /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}

echo "Kafka installed."
