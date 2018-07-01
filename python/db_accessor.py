import os
import redis
from flask import current_app

pool = redis.ConnectionPool(host='localhost', port=6379, db=0)
r = redis.StrictRedis(connection_pool=pool)

password_key = "password"
last_login_at_key = "last_login_at"
last_login_ip_key = "last_login_ip"
locked_user_key = "locked_users"
banned_ip_key = "banned_ips"

config = {
    'user_lock_threshold': int(
        os.environ.get('ISU4_USER_LOCK_THRESHOLD', 3)),
    'ip_ban_threshold': int(os.environ.get('ISU4_IP_BAN_THRESHOLD', 10))
}

"""
ban
"""


def set_banned_ip(ip):
    current_app.logger.info("{} is locked.".format(ip))
    r.sadd(banned_ip_key, ip)


def is_banned_ip(ip):
    current_app.logger.info("ban check [{}] ban:{} count:{} ".format(
        ip, r.sismember(banned_ip_key, ip), get_fail_ip(ip)))
    return r.sismember(banned_ip_key, ip)


def get_banned_ips():
    print r.smembers(banned_ip_key)
    return r.smembers(banned_ip_key)


def set_locked_user(user_id):
    print "locked", user_id
    r.sadd(locked_user_key, user_id)


def get_locked_users():
    return r.smembers(locked_user_key)


def is_locked_user(user_id):
    print "locked user:", r.sismember(locked_user_key,
                                      user_id), "count: ", get_fail_user(
        user_id)
    return r.sismember(locked_user_key, user_id)


def reset():
    """Debug"""
    r.srem(banned_ip_key, '127.0.0.1')
    r.srem(locked_user_key, 'isucon2')


"""
user
"""


def get_user(user_id):
    key = _get_user_key(user_id)
    if r.exists(key):
        user = r.hgetall(key)
        return (user[password_key],
                user.get(last_login_at_key),
                user.get(last_login_ip_key))
    return None, None, None


def set_last_login_time(user_id, time_):
    key = _get_user_key(user_id)
    r.hset(key, last_login_at_key, time_)


def set_last_ip(user_id, ip):
    key = _get_user_key(user_id)
    r.hset(key, last_login_ip_key, ip)


"""
fail user
"""


def get_fail_user(user_id):
    key = _get_fail_user_key(user_id)
    if r.exists(key):
        return int(r.get(key))
    return 0


def reset_fail_user(user_id):
    key = _get_fail_user_key(user_id)
    r.set(key, 0)


def inc_fail_user(user_id):
    global config
    key = _get_fail_user_key(user_id)
    v = r.incr(key, 1)
    if v >= config['user_lock_threshold']:
        set_locked_user(user_id)


"""
fail ip
"""


def get_fail_ip(ip):
    key = _get_fail_ip_key(ip)
    if r.exists(key):
        return int(r.get(key))
    return 0


def reset_fail_ip(ip):
    key = _get_fail_ip_key(ip)
    r.set(key, 0)


def inc_fail_ip(ip):
    global config
    key = _get_fail_ip_key(ip)
    v = r.incr(key, 1)
    if v >= config['ip_ban_threshold']:
        set_banned_ip(ip)


"""
keys
"""


def _get_user_key(user_id):
    return "users_{}".format(user_id)


def _get_fail_user_key(user_id):
    return "fail_user_{}".format(user_id)


def _get_fail_ip_key(ip):
    return "fail_ip_{}".format(ip)


if __name__ == '__main__':
    user = "test"
    ip = "127.0.0.1"
    reset_fail_ip(ip)
    reset_fail_user(user)

    k = _get_user_key(user)
    # user
    r.hset(k, password_key, "hoge")
    r.hset(k, last_login_at_key, "2018-06-24 10:13:04")
    r.hset(k, last_login_ip_key, "0.0.0.0")

    pw, last_login, last_ip = get_user(user)
    assert pw == "hoge"
    assert last_login == "2018-06-24 10:13:04"
    assert last_ip == "0.0.0.0"

    # lock check
    assert get_fail_user(user) == 0
    for i in range(3):
        inc_fail_user(user)
    assert get_fail_user(user) == 3

    # ban check
    assert get_fail_ip(ip) == 0
    for i in range(10):
        inc_fail_ip(ip)
    assert get_fail_ip(ip) == 10
