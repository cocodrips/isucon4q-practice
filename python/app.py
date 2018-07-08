from logging import getLogger
import db_accessor as db
from datetime import datetime

from flask import (
    Flask, request, redirect, session, url_for, flash, jsonify,
    render_template, _app_ctx_stack, logging
)
from werkzeug.contrib.fixers import ProxyFix

import os, hashlib

config = {}
app = Flask(__name__, static_url_path='')
app.wsgi_app = ProxyFix(app.wsgi_app)
app.secret_key = os.environ.get('ISU4_SESSION_SECRET', 'shirokane')
app.debug = 1

time_format = "%Y-%m-%d %H:%M:%S"


def load_config():
    global config
    config = {
        'user_lock_threshold': int(
            os.environ.get('ISU4_USER_LOCK_THRESHOLD', 3)),
        'ip_ban_threshold': int(os.environ.get('ISU4_IP_BAN_THRESHOLD', 10))
    }
    return config


def get_current_time():
    return datetime.now().strftime(time_format)


def get_time(time_string):
    return datetime.strptime(time_string, time_format)


def calculate_password_hash(password, salt):
    return hashlib.sha256(password + ':' + salt).hexdigest()


def login_log(succeeded, login, user_id=None):
    print('login_log: ' + str(succeeded) + ', ' + login + ', ' + str(
        user_id) + ',' + request.remote_addr)

    if succeeded:
        if user_id:
            db.set_last_login_time(user_id, get_current_time())
        else:
            db.set_last_ip(user_id, request.remote_addr)
    else:
        if user_id:
            db.reset_fail_user(user_id)
        else:
            db.reset_fail_ip(request.remote_addr)


def user_locked(user):
    if not user:
        return None
    return db.is_locked_user(user)


def ip_banned():
    return db.is_banned_ip(request.remote_addr)


def attempt_login(login, password):
    print("attempt_login", login, password)
    user = login
    pw, last_login, last_ip = db.get_user(user)

    if ip_banned():
        return [None, 'banned', None, None]

    if user_locked(user):
        return [None, 'locked', None, None]

    # Success
    if pw == password:
        db.set_last_login_time(user, get_current_time())
        db.set_last_ip(user, request.remote_addr)
        db.reset_fail_ip(request.remote_addr)
        db.reset_fail_user(user)
        return [user, None, last_login, last_ip]
    elif user:
        db.inc_fail_user(user)
        db.inc_fail_ip(request.remote_addr)
        return [None, 'wrong_password', None, None]
    else:
        db.inc_fail_ip(request.remote_addr)
        return [None, 'wrong_login', None, None]


class User:
    def __init__(self, user_id, last_login_at, last_login_ip):
        self.user_id = user_id
        self.last_login_at = last_login_at
        self.last_login_ip = last_login_ip


def current_user():
    if not session['user_id']:
        return None

    user_id = session['user_id']
    _, last_login, last_ip = db.get_user(user_id)
    u = User(user_id, session['last_login'], session['last_ip'])
    if not u.last_login_at:
        u.last_login_at = last_login
        u.last_login_ip = last_ip
    return u


def banned_ips():
    ips = db.get_banned_ips()
    return ips


def locked_users():
    users = db.get_locked_users()
    return users


@app.route('/')
def index():
    app.logger.debug("/")
    return render_template('index.html')


@app.route('/login', methods=['POST'])
def login():
    app.logger.debug("/login")
    login = request.form['login']
    password = request.form['password']
    user, err, last_login, last_ip = attempt_login(login, password)

    if user:
        app.logger.debug("Login Successed({}).".format(user))
        session['user_id'] = login
        session['last_login'] = last_login
        session['last_ip'] = last_ip
        return redirect(url_for('mypage'))
    else:
        app.logger.debug("Login failed.")
        app.logger.error('err = ' + err)
        if err == 'locked':
            flash('This account is locked.')
        elif err == 'banned':
            flash("You're banned.")
        else:
            flash('Wrong username or password')
        return redirect(url_for('index'))


@app.route('/mypage')
def mypage():
    user = current_user()
    if user:
        return render_template('mypage.html', user=user)
    else:
        flash('You must be logged in')
        return redirect(url_for('index'))


@app.route('/report')
def report():
    response = jsonify(
        {'banned_ips': list(banned_ips()),
         'locked_users': list(locked_users())})
    response.status_code = 200
    return response


@app.route('/reset')
def reset():
    db.reset()
    return "OK"


if __name__ == '__main__':
    load_config()
    port = int(os.environ.get('PORT', '5000'))
    app.run(debug=1, host='0.0.0.0', port=port)
else:
    load_config()
