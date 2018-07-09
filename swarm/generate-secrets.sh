#!/bin/sh

cat <<EOF > ./secrets/cliet-ssl.properites
security.protocol=SSL
ssl.truststore.location=/secrets/truststore.jks
ssl.truststore.password=${PASSWORD}
ssl.keystore.location=/secrets/keystore.jks
ssl.keystore.password=${PASSWORD}
EOF

cat <<EOF > ./secrets/password_keystore.txt
${PASSWORD}
EOF

cat <<EOF > ./secrets/password_truststore.txt
${PASSWORD}
EOF

cat <<EOF > ./secrets/zookeeper_kafka_jaas.conf
Client {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       username="kafka"
       password="${PASSWORD}";
};
EOF

cat <<EOF > ./secrets/zookeeper_server_jaas.conf
QuorumServer {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       user_zookeeper="${PASSWORD}";
};

QuorumLearner {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       username="zookeeper"
       password="${PASSWORD}";
};

Server {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       user_super="${PASSWORD}"
       user_kafka="${PASSWORD}";
};
EOF
