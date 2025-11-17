#!/bin/bash
MYSQL_ROOT_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
PWD=$(pwd)
docker run --name w5db \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -v $PWD/conf.d:/etc/mysql/conf.d \
  -v $PWD/init.sql:/docker-entrypoint-initdb.d/init.sql \
  -v /var/lib/mysql:/var/lib/mysql:Z \
  --rm mariadb:latest

