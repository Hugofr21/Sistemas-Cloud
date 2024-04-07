#!/bin/bash

dnf update -y && dnf upgrade -y
dnf -y install  lvm2
dnf -y install centos-release-ceph-reef epel-release
dnf -y install ceph
yum -y install nc
mkdir -p /etc/ceph

# systemctl stop firewalld
# systemctl disable firewalld

mkdir -p /root/.ssh
echo "${SSH_PUBLIC_KEY}" | base64 -d > /root/.ssh/id_rsa.pub
echo "${SSH_PUBLIC_KEY}" | base64 -d > /root/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 400 ~/.ssh/id_rsa
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/authorized_keys
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
ssh-keyscan -H node01 >> ~/.ssh/known_hosts
service sshd restart
firewall--cmd --reload


