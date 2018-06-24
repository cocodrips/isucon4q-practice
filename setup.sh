#!/bin/bash

# Install programs
sudo yum install -y dstat htop tcpdump wget curl emacs vim-enhanced iotop unzip

# Install alp
wget https://github.com/tkuchiki/alp/releases/download/v0.3.1/alp_linux_amd64.zip
unzip alp_linux_amd64.zip
sudo mv alp /user/local/bin/alp
rm alp_linux_amd64.zip

# Install pt-query-digest
sudo yum install -y https://www.percona.com/downloads/percona-toolkit/3.0.10/binary/redhat/6/x86_64/percona-toolkit-3.0.10-1.el6.x86_64.rpm
