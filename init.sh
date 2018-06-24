#!/bin/bash
set -x
set -e
cd $(dirname $0)

myuser=root
mydb=isu4_qualifier
myhost=127.0.0.1
myport=3306
mysql -h ${myhost} -P ${myport} -u ${myuser} -e "DROP DATABASE IF EXISTS ${mydb}; CREATE DATABASE ${mydb}"
mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/schema.sql
mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/dummy_users.sql
mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/dummy_log.sql

mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} << EOS
ALTER TABLE login_log ADD INDEX ip(ip);
ALTER TABLE login_log ADD INDEX user_id(user_id);
EOS

mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} << EOS
CREATE TABLE fail_count (
  `id`      INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT,
  `fail`    INT          DEFAULT 0
);
  
INSERT INTO fail_count(user_id, fail)
  SELECT
    ll.user_id,
    count(1) AS fail
  FROM login_log ll
    LEFT JOIN
    (SELECT
       user_id,
       MAX(id) AS last_succeed
     FROM
       login_log
     WHERE succeeded = 1
     GROUP BY user_id) ls ON ll.user_id = ls.user_id
  WHERE id > IFNULL(ls.last_succeed, 10000000000)
  GROUP BY ll.user_id;
EOS
