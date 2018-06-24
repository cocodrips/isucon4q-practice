.PHONY: main mysql nginx ctrl bench

main: mysql nginx bench
	echo "OK"
	
mysql: 
	sudo ln -sf $(pwd)/my.cnf /etc/my.cnf
	sudo rm /var/log/mysql/*
	sudo service mysqld restart

nginx: 
	sudo ln -sf $(pwd)/nginx /etc/nginx
	sudo rm -f /var/log/nginx/access.log /var/log/nginx/error.log
	sudo touch /var/log/nginx/access.log /var/log/nginx/error.log
	sudo service nginx restart
	
ctrl:
	sudo /etc/init.d/supervisord stop
	sudo ln -sf $(pwd)/supervisord.conf /etc/supervisord.conf	
	sudo /etc/init.d/supervisord start

bench:
	sudo su - isucon -c '/home/isucon/benchmarker bench --workload 4'
