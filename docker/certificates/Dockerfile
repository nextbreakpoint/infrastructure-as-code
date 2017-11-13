FROM ubuntu:16.04

VOLUME /output

COPY generate.sh /generate.sh

RUN chmod u+x /generate.sh

RUN apt-get update -y && apt-get install -y openssl ca-certificates

RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update -y

RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer
RUN apt-get install -y oracle-java8-set-default

CMD "/generate.sh"
