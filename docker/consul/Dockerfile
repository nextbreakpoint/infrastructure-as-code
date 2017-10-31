FROM ubuntu:16.04

VOLUME /output

COPY generate.sh /generate.sh

RUN chmod u+x /generate.sh

RUN apt-get update -y && apt-get install -y openssl ca-certificates

CMD "/generate.sh"
