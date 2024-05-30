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
if echo "${SSL_PRIVATE_KEY_CLIENT}" | base64 -d > /etc/ssl/ssl_private_key.pem; then
    echo "SSL private key saved successfully."
else
    echo "Error: Failed to save SSL private key."
fi

if echo "${SSL_CERT_KEY_CLIENT}" | base64 -d > /etc/ssl/ssl_certificate.pem; then
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

sudo systemctl stop firewalld
sudo systemctl disable firewalld


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
snap list
snap find kubernetes
snap install certbot --classic
sudo certbot --nginx -d video-cloud


##------------ Memcached  --------------------
#vi /etc/sysconfig/memcached
sed -i -e 's/^PORT=.*/PORT="433/"' /etc/sysconfig/memcached
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
base64 -d <<< "${main_nginx}" > /etc/nginx/nginx.conf
base64 -d <<< "${server_config_nginx}" > /etc/nginx/conf.d/video-server.conf
mkdir -p /usr/share/nginx/video-cloud
mkdir -p /var/cache/nginx 

sudo systemctl start nginx
sudo systemctl enable nginx
systemctl reload nginx

firewall-cmd --runtime-to-permanent
setsebool -P httpd_can_network_connect on

openssl genpkey -algorithm RSA -out /etc/ssl/private/blog.ns1video22world.com.key -pkeyopt rsa_keygen_bits:2048
openssl req -new -key /etc/ssl/private/blog.ns1video22world.com.key -out /etc/ssl/certs/blog.ns1video22world.com.csr -subj "/C=PT/ST=Lisboa/L=Lisboa/O=video22cloud/CN=blog.ns1video22world.com/emailAddress=root@video22cloud.com"
openssl x509 -req -days 365 -in /etc/ssl/certs/blog.ns1video22world.com.csr -signkey /etc/ssl/private/blog.ns1video22world.com.key -out /etc/ssl/certs/blog.ns1video22world.com.crt

base64 -d <<< "${DOCKER_SYSTEMD}" > /etc/systemd/system/cdn.service

sudo systemctl daemon-reload
sudo systemctl enable cdn.service
sudo systemctl start cdn.service
sudo systemctl status cdn.service

sudo semanage port -a -t http_port_t -p tcp 444
