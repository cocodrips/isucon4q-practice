.PHONY: main sysctl mysql nginx ctrl bench

main: sysctl mysql nginx ctrl bench
	echo "OK"

sysctl:
	sudo ln -sf $(PWD)/sysctl.conf /etc/sysctl.conf
	sudo sysctl -a

mysql: 
	sudo ln -sf $(PWD)/my.cnf /etc/my.cnf
	sudo rm -f /var/log/mysql/*
	sudo service mysqld restart

nginx: 
	sudo ln -sf $(PWD)/nginx /etc/nginx
	sudo rm -f /var/log/nginx/access.log /var/log/nginx/error.log
	sudo touch /var/log/nginx/access.log /var/log/nginx/error.log
	sudo service nginx restart

python:
	echo "Pass python"

ctrl:
	sudo supervisorctl reload

bench:
	sudo su - isucon -c 'ln -sf $(PWD)/init.sh init.sh'
	sudo su - isucon -c '/home/isucon/benchmarker bench --workload 4'
