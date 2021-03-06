FROM openjdk:8-jre-slim

ARG kafka_version
ARG scala_version

ENV DEBIAN_FRONTEND noninteractive
ENV SCALA_VERSION $scala_version
ENV KAFKA_VERSION $kafka_version
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"

# Install Kafka, Zookeeper and other needed things
RUN apt-get update && \
    apt-get install -y curl dnsutils && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    curl -LO http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

RUN curl -LO "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip" -H 'Cookie: oraclelicense=accept-securebackup-cookie' && \
    unzip jce_policy-8.zip && \
    rm jce_policy-8.zip && \
    cp -v UnlimitedJCEPolicyJDK8/*.jar /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security

ADD start-kafka.sh /usr/bin/start-kafka.sh

EXPOSE 9092

CMD ["/usr/bin/start-kafka.sh"]
