ALTER TABLE login_log ADD INDEX ip(ip);
ALTER TABLE login_log ADD INDEX user_id(user_id);

CREATE TABLE IF NOT EXISTS `user_fail_count` (
  `id`      INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNIQUE,
  `fail`    INT          DEFAULT 0
);


INSERT INTO `user_fail_count` (user_id, fail)
  SELECT
    DISTINCT
    ll.user_id as user_id,
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
  WHERE id > IFNULL(ls.last_succeed, 1000000)
  GROUP BY ll.user_id;



CREATE TABLE IF NOT EXISTS `ip_fail_count` (
  `id`      INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `ip` varchar(255) NOT NULL UNIQUE,
  `fail`    INT          DEFAULT 0
);

INSERT INTO `ip_fail_count` (ip, fail)
  SELECT
    DISTINCT
    ll.ip as ip,
    count(1) AS fail
  FROM login_log ll
    LEFT JOIN
    (SELECT
       ip,
       MAX(id) AS last_succeed
     FROM
       login_log
     WHERE succeeded = 1
     GROUP BY ip) ls ON ll.ip = ls.ip
  WHERE id > IFNULL(ls.last_succeed, 1000000)
  GROUP BY ll.ip;

