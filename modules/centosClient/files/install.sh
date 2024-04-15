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

mkdir -p /root/etc/ssl
if echo "${SSL_PRIVATE_KEY_CLIENT}" | base64 -d > /root/etc/ssl/ssl_private_key.pem; then
    echo "SSL private key saved successfully."
else
    echo "Error: Failed to save SSL private key."
fi

if echo "${SSL_CERT_KEY_CLIENT}" | base64 -d > /root/etc/ssl/ssl_certificate.pem; then
    echo "SSL certificate saved successfully."
else
    echo "Error: Failed to save SSL certificate."
fi

chmod 700 ~/.ssh
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
# sudo dnf --enablerepo=epel -y install snapd
# sudo ln -s /var/lib/snapd/snap /snap
# snap list
# snap find kubernetes
# snap install certbot --classic
# sudo certbot --nginx -d video-cloud


##------------ Memcached  --------------------
#vi /etc/sysconfig/memcached
sed -i -e 's/^PORT=.*/PORT="2000/"' /etc/sysconfig/memcached
sed -i -e 's/^CACHESIZE=.*/CACHESIZE="1024"/' /etc/sysconfig/memcached
sudo systemctl enable --now memcached
sudo firewall-cmd --add-service=memcache
sudo firewall-cmd --runtime-to-permanent

##------------ Nginx  --------------------
systemctl enable --now nginx
firewall-cmd --add-service=http
firewall-cmd --runtime-to-permanent
firewall-cmd --add-service=https
firewall-cmd --runtime-to-permanent

base64 -d <<< "${server_config_nginx}" > /etc/nginx/conf.d/video-server.conf
mkdir -p /usr/share/nginx/video-cloud
systemctl reload nginx
setsebool -P httpd_can_network_connect on