#!/bin/sh

docker run --rm -it --net=services postgres:latest sh -c "PGPASSWORD=password psql -h postgres -U postgres postgres -c \"CREATE DATABASE test;\""

docker run --rm -it --net=services postgres:latest sh -c "PGPASSWORD=password psql -h postgres -U postgres test -c \"CREATE USER test WITH PASSWORD 'password'\""

docker run --rm -it --net=services postgres:latest sh -c "PGPASSWORD=password psql -h postgres -U postgres test -c \"GRANT ALL PRIVILEGES ON DATABASE test TO test;\""
