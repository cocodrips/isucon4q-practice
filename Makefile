.PHONY: main mysql nginx ctrl bench python

main: mysql nginx bench
	echo "OK"

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
	sudo su - isucon -c "pip install -r $(PWD)/python/requirements.txt"
	
ctrl:
	sudo /etc/init.d/supervisord stop
	sudo ln -sf $(PWD)/supervisord.conf /etc/supervisord.conf	
	sudo /etc/init.d/supervisord start

bench:
	sudo su - isucon -c 'ln -sf $(PWD)/init.sh init.sh'
	sudo su - isucon -c '/home/isucon/benchmarker bench --workload 4'
