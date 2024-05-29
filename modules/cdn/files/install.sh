#!/bin/bash

dnf update -y && dnf upgrade -y
sudo yum install -y zip
dnf -y install bind bind-utils
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo iptables -A INPUT -p tcp --dport 8077 -j ACCEPT
firewall-cmd --add-service=dhcp
firewall-cmd --runtime-to-permanent


base64 -d <<< "${NAMED_CONF}" > /etc/named.conf

base64 -d <<< "${VIDEO_DB}" > /var/named/video.world.db

base64 -d <<< "${INVERSA_DB}" > /var/named/10.0.16.172.db

mkdir -p /etc/sysconfig/named
base64 -d <<< "${NAMED_SYSCONFIG}" > /etc/sysconfig/named

chown root:named /etc/named.conf
chown -R root:named /var/named/video.world.db
chown -R root:named /var/named/10.0.16.172.db
chown -R root:named /etc/sysconfig/named
chmod 640 /etc/named.conf
chmod 640 /var/named/video.world.db
chmod 640 /var/named/10.0.16.172.db
chmod 750 /etc/sysconfig/named

sudo systemctl restart named
sudo systemctl enable named

sudo systemctl start docker

sysctl -w net.ipv4.ip_forward=1

if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

sudo iptables -A INPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables-save > /etc/sysconfig/iptables

curl -o api-spring.zip https://storage.googleapis.com/bucket-cloud-api/api-spring.zip
unzip api-spring.zip
docker build -t cdn .
docker run -p 8077:8077 cdn


