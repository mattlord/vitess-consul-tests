#!/bin/bash

mysql -h127.0.0.1 -uroot -ppassw0rd -P33306 \
    -e 'CREATE TABLE IF NOT EXISTS `vitess-test`.`users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(25) COLLATE utf8_unicode_ci NOT NULL,
  `password` varchar(30) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
);'

count=0
while true; do
	echo "$(date) :: $count"
  time mysql -h127.0.0.1 -uroot -ppassw0rd \
      -e 'insert into users(username,password) values("user1","21321");';

  count=$((count+1))
  echo
  sleep 1
done;
