require "redis"
require "csv"

redis = Redis.new

# ユーザー情報のインサート
dummy_users = CSV.read('/home/isucon/sql/dummy_users.tsv', col_sep: '\t', headers: false)
dummy_users.each do |du|
  redis.hmset("users_#{du[1]}", "password_hash", du[4], "salt", du[3])
end

# ユーザーログのインサート
# INSERT INTO `login_log` (`created_at`, `user_id`, `login`, `ip`, `succeeded`) VALUES ('2014-02-22 00:00:00 +0900', 199399, 'npm', '127.250.0.226', 1),('2014-02-22 00:00:04 +0900', 195690, 'geovany_mueller', '127.200.1.1', 0),('2014-02-22 00:00:08 +0900', 195802, 'auguue', '127.250.0.51', 1),('2014-02-22 00:00:09 +0900', 199894, 'marilpz', '127.250.0.239', 1),('2014-02-22 00:00:12 +0900', 196536, 'shanna_armstrong', '127.200.1.2', 0),('2014-02-22 00:00:17 +0900', 195860, 'randbv', '127.200.1.3', 0),('2014-02-22 00:00:19 +0900', 197238, 'zachery_pfeffer', '127.200.1.4', 0),('2014-02-22 00:00:21 +0900', 195431, 'marianne_rice', '127.200.1.5', 0),('2014-02-22 00:00:22 +0900', 196896, 'adelns', '127.200.1.6', 0),('2014-0
dummy_logs = CSV.read('./login_log.tsv', col_sep: '\t', headers:false)
dummy_logs.each do |l|
  user_fail_key = "fail_user_#{l[2]}"
  ip_fail_key = "fail_ip_#{l[4]}"
  if l[5] == "1"
    redis.set(user_fail_key, 0)
    redis.set(ip_fail_key, 0)
  else
    redis.incr(user_fail_key)
    redis.incr(ip_fail_key)
  end
end
