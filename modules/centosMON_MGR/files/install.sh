#!/bin/bash

dnf update -y && dnf upgrade -y
dnf -y install lvm2
dnf -y install centos-release-ceph-reef epel-release
dnf -y install ceph
mkdir -p /etc/ceph
dnf -y install ceph
dnf install ceph-mgr-dashboard
yum -y install nc
dnf -y install centos-release-nfs-ganesha5
dnf install nfs-ganesha-ceph
dnf install epel-release
dnf -y install rsync rsync-daemon

# systemctl stop firewalld
# systemctl disable firewalld     
mkdir -p /root/.ssh
base64 -d <<< "${ssh_private_key}" > /root/.ssh/id_rsa
base64 -d <<< "${ssh_public_key}" > /root/.ssh/id_rsa.pub
base64 -d <<< "${ssh_public_key}" > /root/.ssh/authorized_keys
base64 -d <<< "${ssh_config}" > /root/.ssh/config
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/authorized_keys
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
ssh-keyscan -H node01 >> ~/.ssh/known_hosts
service sshd restart
firewall-cmd --add-service=ssh
firewall-cmd --runtime-to-permanent
base64 -d <<< "${ceph_conf}" > /etc/ceph/ceph.conf

sudo systemctl stop firewalld
sudo systemctl disable firewalld

# generate secret key for Cluster monitoring
ceph-authtool --create-keyring /etc/ceph/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'

# generate secret key for Cluster admin
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'

# generate key for bootstrap
ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'

# import generated key
ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring

# generate monitor map
FSID=$(grep "^fsid" /etc/ceph/ceph.conf | awk {'print $NF'})
NODENAME=$(grep "^mon initial" /etc/ceph/ceph.conf | awk {'print $NF'})
NODEIP=$(grep "^mon host" /etc/ceph/ceph.conf | awk {'print $NF'})
monmaptool --create --add $NODENAME $NODEIP --fsid $FSID /etc/ceph/monmap


# create a directory for Monitor Daemon
mkdir /var/lib/ceph/mon/ceph-node01

# associate key and monmap to Monitor Daemon
ceph-mon --cluster ceph --mkfs -i $NODENAME --monmap /etc/ceph/monmap --keyring /etc/ceph/ceph.mon.keyring

chown ceph:ceph /etc/ceph/ceph.*
chown -R ceph:ceph /var/lib/ceph/mon/ceph-node01 /var/lib/ceph/bootstrap-osd
systemctl enable --now ceph-mon@$NODENAME

# enable Messenger v2 Protocol
ceph mon enable-msgr2
ceph config set mon auth_allow_insecure_global_id_reclaim false

# enable Placement Groups auto scale module
ceph mgr module enable pg_autoscaler

mkdir /var/lib/ceph/mgr/ceph-node01

# create a keyring mgr
ceph auth get-or-create mgr.$NODENAME mon 'allow profile mgr' osd 'allow *' mds 'allow *'
ceph auth get-or-create mgr.node01 > /etc/ceph/ceph.mgr.admin.keyring
cp /etc/ceph/ceph.mgr.admin.keyring /var/lib/ceph/mgr/ceph-node01/keyring
chown ceph:ceph /etc/ceph/ceph.mgr.admin.keyring
chown -R ceph:ceph /var/lib/ceph/mgr/ceph-node01
systemctl enable --now ceph-mgr@$NODENAME


# policy settings
base64 -d <<< "${cephmon_te}" > cephmon.te
checkmodule -m -M -o cephmon.mod cephmon.te
semodule_package --outfile cephmon.pp --module cephmon.mod
semodule -i cephmon.pp

firewall settings
firewall-cmd --add-service=ceph-mon
firewall-cmd --runtime-to-permanent
firewall-cmd --add-service=nfs
firewall-cmd --runtime-to-permanent

ssh-copy-id node02
ssh-copy-id node03
ssh-copy-id node04client

# Configure the firewall settings for the current machine
for NODE in node01 node02 node03 node04client
do
    ssh $NODE "firewall-cmd --add-service=ceph; firewall-cmd --runtime-to-permanent" -q
done


# VMs node02 node03 OSD configuration
for NODE in node01 node02 node03
do
    if [ ! ${NODE} = "node01" ]
    then
        scp /etc/ceph/ceph.conf ${NODE}:/etc/ceph/ceph.conf
        scp /etc/ceph/ceph.client.admin.keyring ${NODE}:/etc/ceph
        scp /var/lib/ceph/bootstrap-osd/ceph.keyring ${NODE}:/var/lib/ceph/bootstrap-osd
    fi
    ssh $NODE \
    "chown ceph:ceph /etc/ceph/ceph.* /var/lib/ceph/bootstrap-osd/*; \
    parted --script /dev/sdb 'mklabel gpt'; \
    parted --script /dev/sdb "mkpart primary 0% 100%"; \
    ceph-volume lvm create --data /dev/sdb1"
done 

##created OSD node01 
# chown ceph:ceph /etc/ceph/ceph.* /var/lib/ceph/bootstrap-osd/*
# parted --script /dev/sdb 'mklabel gpt'
# parted --script /dev/sdb 'mkpart primary 0% 100%'
# ceph-volume lvm create --data /dev/sdb1
   

# crete dashboard ceph
ceph mgr module enable dashboard
ceph mgr module ls | grep dashboard
ceph dashboard create-self-signed-cert
echo "password" > pass.txt
ceph dashboard ac-user-create ceph -i pass.txt administrator
ceph mgr services


for NODE in node01
 do
     if [ $NODE == "node01" ]; then
         firewall-cmd --add-port=8443/tcp
         firewall-cmd --runtime-to-permanent --quiet
     fi

     ssh $NODE "firewall-cmd --add-port=8443/tcp; firewall-cmd --runtime-to-permanent" -q
 done

systemctl daemon-reload
systemctl restart ceph-mgr@node01.service


# file rync backup postgresql
# Copy files or directories from one location to an another localtion by [rsync].
sudo base64 -d <<< "${rync_conf}" > /etc/rsyncd.conf
mkdir -p /home/backup
systemctl enable --now rsyncd
sudo systemctl start rsync
sudo systemctl enable rsyncd
setsebool -P rsync_full_access on
firewall-cmd --add-service=rsyncd --permanent
firewall-cmd --reload

#FileSystem
ssh-copy-id node04Client
scp /etc/ceph/ceph.conf node04Client:/etc/ceph/
scp /etc/ceph/ceph.client.admin.keyring node04Client:/etc/ceph/
ssh node04Client "chown ceph:ceph /etc/ceph/ceph.*"
mkdir -p /var/lib/ceph/mds/ceph-node01
ceph-authtool --create-keyring /var/lib/ceph/mds/ceph-node01/keyring --gen-key -n mds.node01
chown -R ceph:ceph /var/lib/ceph/mds/ceph-node01
ceph auth add mds.node01 osd "allow rwx" mds "allow" mon "allow profile mds" -i /var/lib/ceph/mds/ceph-node01/keyring
systemctl enable --now ceph-mds@node01

ceph osd pool create cephfs_data 32
ceph osd pool create cephfs_metadata 32
ceph osd pool set cephfs_data bulk true
ceph fs new cephfs cephfs_metadata cephfs_data
ceph fs ls
ceph fs new cephfs cephfs_metadata cephfs_data
ceph mds stat
ceph fs status cephfs

# # Allow the MDS to go down and mark the filesystem offline
 ceph mds set allow_down true
 ceph mds set allow_new_snaps true
 ceph mds set allow_multimds true

# # send to client host executed keuring permmisions rwx-------
scp /etc/ceph/ceph.client.admin.keyring root@node04client:/etc/ceph
scp /etc/ceph/ceph.conf root@node04client:/etc/ceph
ssh -o StrictHostKeyChecking=no root@node04client "
    ceph-authtool -p /etc/ceph/ceph.client.admin.keyring > admin.key; \
    chmod 600 admin.key;
"
