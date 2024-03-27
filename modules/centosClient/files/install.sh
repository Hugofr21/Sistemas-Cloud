#!/bin/bash


dnf update -y && dnf upgrade -y
dnf module -y install postgresql:13
sudo yum -y install epel-release
dnf -y install centos-release-ceph-reef epel-release
dnf -y install ceph
yum -y install nc
dnf -y install rsync
dnf -y install nfs-utils
 dnf -y install zip 

# systemctl stop firewalld
# systemctl disable firewalld

mkdir -p /root/.ssh
echo "${SSH_PUBLIC_KEY_CLIENT}" | base64 -d > /root/.ssh/id_rsa.pub
echo "${SSH_PUBLIC_KEY_CLIENT}" | base64 -d > /root/.ssh/authorized_keys

chmod 400 ~/.ssh/id_rsa
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/authorized_keys
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
ssh-keyscan -H node01 >> ~/.ssh/known_hosts
service sshd restart


postgresql-setup --initdb
systemctl enable --now postgresql

 sudo iptables -A INPUT -p tcp --dport 6700:6900 -s 10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6 -j ACCEPT
 sudo iptables -A OUTPUT -p tcp --sport 6700:6900 -d 10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6 -j ACCEPT
 sudo iptables -A INPUT -p tcp --dport 5432 -s 192.168.1.71 -j ACCEPT
 sudo iptables -A OUTPUT -p tcp --sport 5432 -d 192.168.1.71 -j ACCEPT
 sudo iptables -A INPUT -i eth0 -m multiport -p tcp -s 10.0.0.0/27 --dports 6800:7300 -j ACCEPT
 iptables-save > /etc/sysconfig/iptables

 firewall-cmd --add-service=ceph --permanent
 firewall-cmd --add-service=postgresql --permanent
 firewall-cmd --add-service=rsyncd --permanent
 firewall-cmd --add-port=5432/tcp 
 firewall-cmd --reload

mkdir -p /var/lib/ceph/mds/ceph-client/



