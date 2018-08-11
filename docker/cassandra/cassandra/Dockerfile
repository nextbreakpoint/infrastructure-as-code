ARG cassandra_version

FROM cassandra:${cassandra_version}

COPY cassandra-entrypoint.sh /cassandra-entrypoint.sh
COPY cassandra-initdb.sh /cassandra-initdb.sh

RUN chmod a+x /cassandra-entrypoint.sh
RUN chmod a+x /cassandra-initdb.sh

RUN sed -i -e "s/authenticator: AllowAllAuthenticator/authenticator: PasswordAuthenticator/g" /etc/cassandra/cassandra.yaml
RUN sed -i -e "s/authorizer: AllowAllAuthorizer/authorizer: CassandraAuthorizer/g" /etc/cassandra/cassandra.yaml

ENTRYPOINT ["/cassandra-entrypoint.sh"]

CMD ["cassandra", "-f"]

USER cassandra
