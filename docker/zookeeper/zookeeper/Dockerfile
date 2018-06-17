ARG zookeeper_version

FROM zookeeper:${zookeeper_version}

COPY entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["zkServer.sh", "start-foreground"]
