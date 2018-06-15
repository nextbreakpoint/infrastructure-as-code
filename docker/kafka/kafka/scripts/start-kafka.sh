#!/bin/sh

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CONNECT: Zookeeper connect parameter, e.g. localhost:2181
# * BROKER_ID: Unique broker id, e.g 1
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic
# * LOG_PATH: configure path where logs are created
# * DELETE_TOPICS: enable/disable deletion of topics
# * TRANSACTION_MAX_TIMEOUT_MS: configure transaction max timeout in millis
# * ADVERTISED_LISTENERS: Configure advertised listeners & listeners
# * KEYSTORE_LOCATION: Configure keystore location
# * KEYSTORE_PASSWORD: Configure keystore password
# * TRUSTSTORE_LOCATION: Configure truststore location
# * TRUSTSTORE_PASSWORD: Configure truststore password
# * KEY_PASSWORD: Configure key password
# * INTER_BROKER_LISTENER_NAME: Configure inter broker listener name
# * SECURITY_INTER_BROKER_PROTOCOL: Configure security inter broker protocol
# * ZOOKEEPER_SET_ACL: Configure Zookeeper set acl

# Set the external host and port
if [ ! -z "$ADVERTISED_HOST" ]; then
    echo "advertised host: $ADVERTISED_HOST"
    if grep -q "^advertised.host.name" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(advertised.host.name)=(.*)/\1=$ADVERTISED_HOST/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nadvertised.host.name=$ADVERTISED_HOST" >> $KAFKA_HOME/config/server.properties
    fi
fi

if [ ! -z "$ADVERTISED_PORT" ]; then
    echo "advertised port: $ADVERTISED_PORT"
    if grep -q "^advertised.port" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(advertised.port)=(.*)/\1=$ADVERTISED_PORT/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nadvertised.port=$ADVERTISED_PORT" >> $KAFKA_HOME/config/server.properties
    fi
fi

if [ ! -z "$ZK_CONNECT" ]; then
    echo "zookeeper connect: $ZK_CONNECT"
    if grep -q "^zookeeper.connect" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(zookeeper.connect)=(.*)/\1=$ZK_CONNECT/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nzookeeper.connect=$ZK_CONNECT" >> $KAFKA_HOME/config/server.properties
    fi
fi

if [ ! -z "$BROKER_ID" ]; then
    echo "broker.id: $BROKER_ID"
    if grep -q "^broker.id" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(broker.id)=(.*)/\1=$BROKER_ID/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nbroker.id=$BROKER_ID" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Allow specification of log retention policies
if [ ! -z "$LOG_RETENTION_HOURS" ]; then
    echo "log retention hours: $LOG_RETENTION_HOURS"
    if grep -q "^log.retention.hours" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(log.retention.hours)=(.*)/\1=$LOG_RETENTION_HOURS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nlog.retention.hours=$LOG_RETENTION_HOURS" >> $KAFKA_HOME/config/server.properties
    fi
fi

if [ ! -z "$LOG_RETENTION_BYTES" ]; then
    echo "log retention bytes: $LOG_RETENTION_BYTES"
    if grep -q "^log.retention.bytes" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(log.retention.bytes)=(.*)/\1=$LOG_RETENTION_BYTES/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nlog.retention.bytes=$LOG_RETENTION_BYTES" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure the default number of log partitions per topic
if [ ! -z "$NUM_PARTITIONS" ]; then
    echo "default number of partition: $NUM_PARTITIONS"
    if grep -q "^num.partitions" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(num.partitions)=(.*)/\1=$NUM_PARTITIONS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nnum.partitions=$NUM_PARTITIONS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Enable/disable auto creation of topics
if [ ! -z "$AUTO_CREATE_TOPICS" ]; then
    echo "auto.create.topics.enable: $AUTO_CREATE_TOPICS"
    if grep -q "^auto.create.topics.enable" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(auto.create.topics.enable)=(.*)/\1=$AUTO_CREATE_TOPICS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nauto.create.topics.enable=$AUTO_CREATE_TOPICS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Enable/disable deletion of topics
if [ ! -z "$DELETE_TOPICS" ]; then
    echo "delete.topic.enable: $DELETE_TOPICS"
    if grep -q "^delete.topic.enable" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(delete.topic.enable)=(.*)/\1=$DELETE_TOPICS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\ndelete.topic.enable=$DELETE_TOPICS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure path where logs are created
if [ ! -z "$LOG_PATH" ]; then
    echo "log path: $LOG_PATH"
    sed -r -i "s/(log.dirs)=(.*)/\1=$LOG_PATH/g" $KAFKA_HOME/config/server.properties
fi

# Configure transaction max timeout in millis
if [ ! -z "$TRANSACTION_MAX_TIMEOUT_MS" ]; then
    echo "transaction max timeout ms: $TRANSACTION_MAX_TIMEOUT_MS"
    if grep -q "^transaction.max.timeout.ms" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(transaction.max.timeout.ms)=(.*)/\1=$TRANSACTION_MAX_TIMEOUT_MS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\ntransaction.max.timeout.ms=$TRANSACTION_MAX_TIMEOUT_MS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure advertised listeners & listeners
if [ ! -z "$ADVERTISED_LISTENERS" ]; then
    echo "advertised listeners: $ADVERTISED_LISTENERS"
    if grep -q "^advertised.listeners" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(advertised.listeners)=(.*)/\1=$ADVERTISED_LISTENERS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nadvertised.listeners=$ADVERTISED_LISTENERS" >> $KAFKA_HOME/config/server.properties
    fi
    if grep -q "^listeners" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(listeners)=(.*)/\1=$ADVERTISED_LISTENERS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nlisteners=$ADVERTISED_LISTENERS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure keystore location
if [ ! -z "$KEYSTORE_LOCATION" ]; then
    echo "keystore location: $KEYSTORE_LOCATION"
    echo "\nssl.keystore.location=$KEYSTORE_LOCATION" >> $KAFKA_HOME/config/server.properties
fi

# Configure keystore password
if [ ! -z "$KEYSTORE_PASSWORD" ]; then
    echo "keystore password is present"
    echo "\nssl.keystore.password=$KEYSTORE_PASSWORD" >> $KAFKA_HOME/config/server.properties
fi

# Configure truststore location
if [ ! -z "$TRUSTSTORE_LOCATION" ]; then
    echo "truststore location: $TRUSTSTORE_LOCATION"
    echo "\nssl.truststore.location=$TRUSTSTORE_LOCATION" >> $KAFKA_HOME/config/server.properties
fi

# Configure truststore password
if [ ! -z "$TRUSTSTORE_PASSWORD" ]; then
    echo "truststore password is present"
    echo "\nssl.truststore.password=$TRUSTSTORE_PASSWORD" >> $KAFKA_HOME/config/server.properties
fi

# Configure key password
if [ ! -z "$KEY_PASSWORD" ]; then
    echo "key password is present"
    echo "\nssl.key.password=$KEY_PASSWORD" >> $KAFKA_HOME/config/server.properties
fi

# Configure inter broker listener name
if [ ! -z "$INTER_BROKER_LISTENER_NAME" ]; then
    echo "inter broker listener name: $INTER_BROKER_LISTENER_NAME"
    if grep -q "^inter.broker.listener.name" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(inter.broker.listener.name)=(.*)/\1=$INTER_BROKER_LISTENER_NAME/g" $KAFKA_HOME/config/server.properties
    else
        echo "\ninter.broker.listener.name=$INTER_BROKER_LISTENER_NAME" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure secutity inter broker protocol
if [ ! -z "$SECURITY_INTER_BROKER_PROTOCOL" ]; then
    echo "security inter broker protocol: $SECURITY_INTER_BROKER_PROTOCOL"
    if grep -q "^security.inter.broker.protocol" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(security.inter.broker.protocol)=(.*)/\1=$SECURITY_INTER_BROKER_PROTOCOL/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nsecurity.inter.broker.protocol=$SECURITY_INTER_BROKER_PROTOCOL" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure Zookeeper set acl
if [ ! -z "$ZOOKEEPER_SET_ACL" ]; then
    echo "zookeeper set acl: $ZOOKEEPER_SET_ACL"
    if grep -q "^zookeeper.set.acl" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(zookeeper.set.acl)=(.*)/\1=$ZOOKEEPER_SET_ACL/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nzookeeper.set.acl=$ZOOKEEPER_SET_ACL" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
