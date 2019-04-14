ARG artifactory_version

FROM docker.bintray.io/jfrog/artifactory-oss:${artifactory_version}

ENV MYSQL_CONNECTOR_VERSION=5.1.44

RUN curl -L -o mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.zip https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.zip

RUN unzip mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.zip

RUN mv /mysql-connector-java-${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar /opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar

RUN rm -fR /mysql-connector-java-${MYSQL_CONNECTOR_VERSION}

RUN rm -f /mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.zip
