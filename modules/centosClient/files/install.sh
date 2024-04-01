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
dnf -y install memcached
dnf -y install nginx
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

 firewall-cmd --add-service=ceph --permanent
 firewall-cmd --add-service=postgresql --permanent
 firewall-cmd --add-service=rsyncd --permanent
 firewall-cmd --add-port=5432/tcp 
 firewall-cmd --reload


mkdir -p /var/lib/ceph/mds/ceph-client/

##------------ ssl certicate --------------------
sudo dnf --enablerepo=epel -y install snapd
sudo ln -s /var/lib/snapd/snap /snap
sud0 echo 'export PATH=$PATH:/var/lib/snapd/snap/bin' > /etc/profile.d/snap.sh
sudo systemctl enable --now snapd.service snapd.socket
sudo snap install -- cerbot --classic
sudo ln -s /snap/bin/certboot /usr/bin/certboot
sudo certbot certonly --agree-tos --webroot -w /var/www/html -d videos-api.cloud

##------------ Memcached  --------------------
#vi /etc/sysconfig/memcached
sed -i -e 's/^PORT=.*/PORT="2000/"' /etc/sysconfig/memcached
sed -i -e 's/^CACHESIZE=.*/CACHESIZE="1024/' /etc/sysconfig/memcached
sudo systemctl enable --now memcached
sudo firewall-cmd --add-service=memcache
sudo firewall-cmd --runtime-to-permanent

##------------ Nginx  --------------------
systemctl enable --now nginx
firewall-cmd --add-service=http
firewall-cmd --runtime-to-permanent