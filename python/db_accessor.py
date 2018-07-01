import redis

pool = redis.ConnectionPool(host='localhost', port=6379, db=0)
r = redis.StrictRedis(connection_pool=pool)


def get_user(user_id):
    """
    :return:
    """
    return r.hgetall(get_user_key(user_id))


def get_fail_user(user_id):
    return int(r.get(get_fail_user_count_key(user_id)))


def get_fail_ip(ip):
    return int(r.get(get_fail_ip_key(ip)))


def get_user_key(user_id):
    return "user_{}".format(user_id)


def get_fail_user_count_key(user_id):
    return "fail_user_{}".format(user_id)


def get_fail_ip_key(ip):
    return "fail_ip_{}".format(ip)


