ALTER TABLE login_log ADD INDEX ip(ip);
ALTER TABLE login_log ADD INDEX user_id(user_id);

CREATE TABLE fail_count (
  `id`      INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT,
  `fail`    INT          DEFAULT 0
);


INSERT INTO fail_count (user_id, fail)
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


