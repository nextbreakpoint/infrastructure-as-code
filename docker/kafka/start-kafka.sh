#!/bin/sh

# Optional ENV variables:
# * PORT: the internal port
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
# * LISTENERS: Configure listeners
# * ADVERTISED_LISTENERS: Configure advertised listeners
# * KEYSTORE_LOCATION: Configure keystore location
# * KEYSTORE_PASSWORD_LOCATION: Configure keystore password by location
# * KEYSTORE_PASSWORD: Configure keystore password
# * TRUSTSTORE_LOCATION: Configure truststore location
# * TRUSTSTORE_PASSWORD_LOCATION: Configure truststore password by location
# * TRUSTSTORE_PASSWORD: Configure truststore password
# * KEY_PASSWORD_LOCATION: Configure key password by location
# * KEY_PASSWORD: Configure key password
# * INTER_BROKER_LISTENER_NAME: Configure inter broker listener name
# * SECURITY_INTER_BROKER_PROTOCOL: Configure security inter broker protocol
# * ZOOKEEPER_SET_ACL: Configure Zookeeper set acl
# * ZOO_JAAS_CONFIG_LOCATION: Configure Zookeeper JAAS config location
# * SASL_JAAS_CONFIG_LOCATION: Configure SASL JAAS config location
# * SSL_ENDPOINT_IDENTIFICATION_ALGORITHM: Configure SSL endpoint identification algorithm
# * DISABLE_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM: Disable SSL endpoint identification algorithm

# Set internal port
if [ -n "$PORT" ]; then
    echo "port: $PORT"
    if grep -q "^port" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(port)=(.*)/\1=$PORT/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nport=$PORT" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set the external host
if [ -n "$ADVERTISED_HOST" ]; then
    echo "advertised host: $ADVERTISED_HOST"
    if grep -q "^advertised.host.name" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(advertised.host.name)=(.*)/\1=$ADVERTISED_HOST/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nadvertised.host.name=$ADVERTISED_HOST" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set the external port
if [ -n "$ADVERTISED_PORT" ]; then
    echo "advertised port: $ADVERTISED_PORT"
    if grep -q "^advertised.port" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(advertised.port)=(.*)/\1=$ADVERTISED_PORT/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nadvertised.port=$ADVERTISED_PORT" >> $KAFKA_HOME/config/server.properties
    fi
fi

if [ -n "$ZK_CONNECT" ]; then
    echo "zookeeper connect: $ZK_CONNECT"
    if grep -q "^zookeeper.connect" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(zookeeper.connect)=(.*)/\1=$ZK_CONNECT/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nzookeeper.connect=$ZK_CONNECT" >> $KAFKA_HOME/config/server.properties
    fi
fi

if [ -n "$BROKER_ID" ]; then
    echo "broker.id: $BROKER_ID"
    if grep -q "^broker.id" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(broker.id)=(.*)/\1=$BROKER_ID/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nbroker.id=$BROKER_ID" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Allow specification of log retention policies
if [ -n "$LOG_RETENTION_HOURS" ]; then
    echo "log retention hours: $LOG_RETENTION_HOURS"
    if grep -q "^log.retention.hours" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(log.retention.hours)=(.*)/\1=$LOG_RETENTION_HOURS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nlog.retention.hours=$LOG_RETENTION_HOURS" >> $KAFKA_HOME/config/server.properties
    fi
fi

if [ -n "$LOG_RETENTION_BYTES" ]; then
    echo "log retention bytes: $LOG_RETENTION_BYTES"
    if grep -q "^log.retention.bytes" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(log.retention.bytes)=(.*)/\1=$LOG_RETENTION_BYTES/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nlog.retention.bytes=$LOG_RETENTION_BYTES" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure the default number of log partitions per topic
if [ -n "$NUM_PARTITIONS" ]; then
    echo "default number of partition: $NUM_PARTITIONS"
    if grep -q "^num.partitions" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(num.partitions)=(.*)/\1=$NUM_PARTITIONS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nnum.partitions=$NUM_PARTITIONS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Enable/disable auto creation of topics
if [ -n "$AUTO_CREATE_TOPICS" ]; then
    echo "auto.create.topics.enable: $AUTO_CREATE_TOPICS"
    if grep -q "^auto.create.topics.enable" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(auto.create.topics.enable)=(.*)/\1=$AUTO_CREATE_TOPICS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nauto.create.topics.enable=$AUTO_CREATE_TOPICS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Enable/disable deletion of topics
if [ -n "$DELETE_TOPICS" ]; then
    echo "delete.topic.enable: $DELETE_TOPICS"
    if grep -q "^delete.topic.enable" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(delete.topic.enable)=(.*)/\1=$DELETE_TOPICS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\ndelete.topic.enable=$DELETE_TOPICS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure path where logs are created
if [ -n "$LOG_PATH" ]; then
    echo "log path: $LOG_PATH"
    sed -r -i "s/(log.dirs)=(.*)/\1=$LOG_PATH/g" $KAFKA_HOME/config/server.properties
fi

# Configure transaction max timeout in millis
if [ -n "$TRANSACTION_MAX_TIMEOUT_MS" ]; then
    echo "transaction max timeout ms: $TRANSACTION_MAX_TIMEOUT_MS"
    if grep -q "^transaction.max.timeout.ms" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(transaction.max.timeout.ms)=(.*)/\1=$TRANSACTION_MAX_TIMEOUT_MS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\ntransaction.max.timeout.ms=$TRANSACTION_MAX_TIMEOUT_MS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure advertised listeners
if [ -n "$ADVERTISED_LISTENERS" ]; then
    echo "advertised listeners: $ADVERTISED_LISTENERS"
    if grep -q "^advertised.listeners" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(advertised.listeners)=(.*)/\1=$ADVERTISED_LISTENERS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nadvertised.listeners=$ADVERTISED_LISTENERS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure listeners
if [ -n "$LISTENERS" ]; then
    echo "listeners: $LISTENERS"
    if grep -q "^listeners" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(listeners)=(.*)/\1=$LISTENERS/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nlisteners=$LISTENERS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure keystore location
if [ -n "$KEYSTORE_LOCATION" ]; then
    echo "keystore location: $KEYSTORE_LOCATION"
    echo "\nssl.keystore.location=$KEYSTORE_LOCATION" >> $KAFKA_HOME/config/server.properties
fi

# Configure keystore password
if [ -n "$KEYSTORE_PASSWORD_LOCATION" ]; then
    echo "keystore password location: $KEYSTORE_PASSWORD_LOCATION"
    echo "\nssl.keystore.password=$(cat $KEYSTORE_PASSWORD_LOCATION)" >> $KAFKA_HOME/config/server.properties
fi

# Configure keystore password
if [ -n "$KEYSTORE_PASSWORD" ]; then
    echo "keystore password is present"
    if grep -q "^ssl.keystore.password" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(ssl.keystore.password)=(.*)/\1=$KEYSTORE_PASSWORD/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nssl.keystore.password=$KEYSTORE_PASSWORD" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure truststore location
if [ -n "$TRUSTSTORE_LOCATION" ]; then
    echo "truststore location: $TRUSTSTORE_LOCATION"
    echo "\nssl.truststore.location=$TRUSTSTORE_LOCATION" >> $KAFKA_HOME/config/server.properties
fi

# Configure truststore password
if [ -n "$TRUSTSTORE_PASSWORD_LOCATION" ]; then
    echo "truststore password location: $TRUSTSTORE_PASSWORD_LOCATION"
    echo "\nssl.truststore.password=$(cat $TRUSTSTORE_PASSWORD_LOCATION)" >> $KAFKA_HOME/config/server.properties
fi

# Configure truststore password
if [ -n "$TRUSTSTORE_PASSWORD" ]; then
    echo "truststore password is present"
    if grep -q "^ssl.truststore.password" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(ssl.truststore.password)=(.*)/\1=$TRUSTSTORE_PASSWORD/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nssl.truststore.password=$TRUSTSTORE_PASSWORD" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure key password
if [ -n "$KEY_PASSWORD_LOCATION" ]; then
    echo "key password location: $KEY_PASSWORD_LOCATION"
    echo "\nssl.key.password=$(cat $KEY_PASSWORD_LOCATION)" >> $KAFKA_HOME/config/server.properties
fi

# Configure key password
if [ -n "$KEY_PASSWORD" ]; then
    echo "key password is present"
    if grep -q "^ssl.key.password" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(ssl.key.password)=(.*)/\1=$KEY_PASSWORD/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nssl.key.password=$KEY_PASSWORD" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure inter broker listener name
if [ -n "$INTER_BROKER_LISTENER_NAME" ]; then
    echo "inter broker listener name: $INTER_BROKER_LISTENER_NAME"
    if grep -q "^inter.broker.listener.name" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(inter.broker.listener.name)=(.*)/\1=$INTER_BROKER_LISTENER_NAME/g" $KAFKA_HOME/config/server.properties
    else
        echo "\ninter.broker.listener.name=$INTER_BROKER_LISTENER_NAME" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure secutity inter broker protocol
if [ -n "$SECURITY_INTER_BROKER_PROTOCOL" ]; then
    echo "security inter broker protocol: $SECURITY_INTER_BROKER_PROTOCOL"
    if grep -q "^security.inter.broker.protocol" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(security.inter.broker.protocol)=(.*)/\1=$SECURITY_INTER_BROKER_PROTOCOL/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nsecurity.inter.broker.protocol=$SECURITY_INTER_BROKER_PROTOCOL" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure Zookeeper set acl
if [ -n "$ZOOKEEPER_SET_ACL" ]; then
    echo "zookeeper set acl: $ZOOKEEPER_SET_ACL"
    if grep -q "^zookeeper.set.acl" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(zookeeper.set.acl)=(.*)/\1=$ZOOKEEPER_SET_ACL/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nzookeeper.set.acl=$ZOOKEEPER_SET_ACL" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Configure SASL JAAS config location
if [ -n "$SASL_JAAS_CONFIG_LOCATION" ]; then
    echo "sasl jaas config location: $SASL_JAAS_CONFIG_LOCATION"
    echo "\nsasl.jaas.config=$SASL_JAAS_CONFIG_LOCATION" >> $KAFKA_HOME/config/server.properties
    # export KAFKA_OPTS="-Djava.security.auth.login.config=$JAAS_CONFIG_LOCATION"
fi

# Configure Zookeeper JAAS config location
if [ -n "$ZOO_JAAS_CONFIG_LOCATION" ]; then
    echo "zookeeper jaas config location: $ZOO_JAAS_CONFIG_LOCATION"
    export KAFKA_OPTS="-Djava.security.auth.login.config=$ZOO_JAAS_CONFIG_LOCATION"
fi

# Configure SSL endpoint identification algorithm
if [ -n "$SSL_ENDPOINT_IDENTIFICATION_ALGORITHM" ]; then
    echo "ssl endpoint identification algorithm: $SSL_ENDPOINT_IDENTIFICATION_ALGORITHM"
    if grep -q "^ssl.endpoint.identification.algorithm" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(ssl.endpoint.identification.algorithm)=(.*)/\1=$SSL_ENDPOINT_IDENTIFICATION_ALGORITHM/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nssl.endpoint.identification.algorithm=$SSL_ENDPOINT_IDENTIFICATION_ALGORITHM" >> $KAFKA_HOME/config/server.properties
    fi
fi
if [ -n $DISABLE_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM ]; then
    echo "ssl endpoint identification algorithm disabled"
    if grep -q "^ssl.endpoint.identification.algorithm" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/(ssl.endpoint.identification.algorithm)=(.*)/\1=/g" $KAFKA_HOME/config/server.properties
    else
        echo "\nssl.endpoint.identification.algorithm=" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
