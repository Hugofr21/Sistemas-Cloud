#!/bin/bash


dnf update -y && dnf upgrade -y
dnf -y install podman lvm2
dnf -y install centos-release-ceph-reef epel-release
dnf -y install ceph
mkdir -p /etc/ceph
yum -y install nc
dnf module -y install postgresql:13

# systemctl stop firewalld
# systemctl disable firewalld

mkdir -p /root/.ssh
echo "${SSH_PUBLIC_KEY_OSD}" | base64 -d > /root/.ssh/id_rsa.pub
echo "${SSH_PUBLIC_KEY_OSD}" | base64 -d > /root/.ssh/authorized_keys

chmod 400 ~/.ssh/id_rsa
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/authorized_keys
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
ssh-keyscan -H node01 >> ~/.ssh/known_hosts
service sshd restart


sudo iptables -A INPUT -p tcp --dport 6700:6900 -s 10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 6700:6900 -d 10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4

