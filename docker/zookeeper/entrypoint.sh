#!/bin/sh

set -e

# Allow the container to be started with `--user`
if [[ "$1" = 'zkServer.sh' && "$(id -u)" = '0' ]]; then
    chown -R "$ZOO_USER" "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_CONF_DIR"
    exec su-exec "$ZOO_USER" "$0" "$@"
fi

# Generate the config only if it doesn't exist
if [[ ! -f "$ZOO_CONF_DIR/zoo.cfg" ]]; then
    CONFIG="$ZOO_CONF_DIR/zoo.cfg"

    echo "clientPort=$ZOO_PORT" >> "$CONFIG"
    echo "dataDir=$ZOO_DATA_DIR" >> "$CONFIG"
    echo "dataLogDir=$ZOO_DATA_LOG_DIR" >> "$CONFIG"

    echo "tickTime=$ZOO_TICK_TIME" >> "$CONFIG"
    echo "initLimit=$ZOO_INIT_LIMIT" >> "$CONFIG"
    echo "syncLimit=$ZOO_SYNC_LIMIT" >> "$CONFIG"

    echo "maxClientCnxns=$ZOO_MAX_CLIENT_CNXNS" >> "$CONFIG"

    for server in $ZOO_SERVERS; do
        echo "$server" >> "$CONFIG"
    done
fi

# Write myid only if it doesn't exist
if [[ ! -f "$ZOO_DATA_DIR/myid" ]]; then
    echo "${ZOO_MY_ID:-1}" > "$ZOO_DATA_DIR/myid"
fi

if [ -n "$ZOO_JAAS_CONFIG_LOCATION" ]; then
    echo "SERVER_JVMFLAGS=\"-Djava.security.auth.login.config=$ZOO_JAAS_CONFIG_LOCATION\"" > $ZOO_CONF_DIR/java.env
fi

if [ "$ZOO_ENABLE_QUORUM_SASL" == "true" ]; then
    echo "quorum.auth.enableSasl=true" >> "$CONFIG"
    echo "quorum.auth.learnerRequireSasl=true" >> "$CONFIG"
    echo "quorum.auth.serverRequireSasl=true" >> "$CONFIG"
    echo "quorum.auth.learner.loginContext=QuorumLearner" >> "$CONFIG"
    echo "quorum.auth.server.loginContext=QuorumServer" >> "$CONFIG"
    echo "quorum.cnxn.threads.size=20" >> "$CONFIG"
fi

if [ "$ZOO_ENABLE_CLIENT_SASL" == "true" ]; then
    echo "authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider" >> "$CONFIG"
    echo "requireClientAuthScheme=sasl" >> "$CONFIG"
fi

exec "$@"
