#!/bin/sh

docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"DROP DATABASE IF EXISTS ``sonar``;\""
docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"DROP DATABASE IF EXISTS ``artdb``;\""

docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"CREATE DATABASE ``sonar`` CHARACTER SET utf8 COLLATE utf8_bin;\""
docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"CREATE DATABASE ``artdb`` CHARACTER SET utf8 COLLATE utf8_bin;\""

docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"CREATE USER IF NOT EXISTS 'sonarqube' IDENTIFIED WITH mysql_native_password BY 'password' PASSWORD EXPIRE NEVER;\""
docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"CREATE USER IF NOT EXISTS 'artifactory' IDENTIFIED WITH mysql_native_password BY 'password' PASSWORD EXPIRE NEVER;\""

docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"GRANT ALL ON ``sonar``.* TO 'sonarqube'@'%';\""
docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"GRANT ALL ON ``artdb``.* TO 'artifactory'@'%';\""

docker run --rm -it --net=services mysql:5.7 sh -c "mysql -h mysql -e \"FLUSH PRIVILEGES;\""

#docker run --rm -it --net=services mysql:5.7 sh -c "mysqladmin -u root password 'password'"
