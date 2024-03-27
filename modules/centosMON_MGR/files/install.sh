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
chmod 400 ~/.ssh/id_rsa
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/authorized_keys
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
ssh-keyscan -H node01 >> ~/.ssh/known_hosts
service sshd restart

base64 -d <<< "${ceph_conf}" > /etc/ceph/ceph.conf

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

# create a directory for Manager Daemon # directory name ⇒ (Cluster Name)-(Node Name)
#node02
NODENAME_NODE02="node02"
INSTALL_CMD="
    dnf -y install centos-release-ceph-reef epel-release; \
    dnf -y install ceph; \
    dnf -y install ceph cephadm; \
    mkdir -p /etc/ceph;
"

wait_for_ssh() {
    while ! ssh $1 true; do
        echo "ssh $1 connecting... "
        sleep 5
    done
}

ssh -o StrictHostKeyChecking=no $NODENAME_NODE02 "$INSTALL_CMD" && wait_for_ssh $NODENAME_NODE02

echo "Processo node02 foi concluído, iniciar node01";


# create auth key
# Gere uma chave secreta para cada MGR, onde {$id}está a letra do MGR:
ceph auth get-or-create mgr.$NODENAME_NODE02 mon 'allow profile mgr' osd 'allow *' mds 'allow *'
ceph auth get-or-create mgr.$NODENAME_NODE02 > /etc/ceph/ceph.mgr.admin.keyring
mkdir /var/lib/ceph/mgr/ceph-$NODENAME_NODE02 && cp /etc/ceph/ceph.mgr.admin.keyring /var/lib/ceph/mgr/ceph-$NODENAME_NODE02/keyring
chown ceph:ceph /etc/ceph/ceph.mgr.admin.keyring
chown -R ceph:ceph /var/lib/ceph/mgr/ceph-$NODENAME_NODE02


#send node02 key generation mgr.node02
scp -o StrictHostKeyChecking=no /etc/ceph/ceph.conf $NODENAME_NODE02:/etc/ceph/
scp -o StrictHostKeyChecking=no /etc/ceph/ceph.mgr.admin.keyring $NODENAME_NODE02:/etc/ceph/
ssh -o StrictHostKeyChecking=no  $NODENAME_NODE02 "mkdir -p /var/lib/ceph/mgr/ceph-node02/"
scp -o StrictHostKeyChecking=no /var/lib/ceph/mgr/ceph-$NODENAME_NODE02/keyring $NODENAME_NODE02:/var/lib/ceph/mgr/ceph-$NODENAME_NODE02/

#active mgr node02
ssh $NODENAME_NODE02 "systemctl enable --now ceph-mgr@$NODENAME_NODE02"
ceph mon mgr add $NODENAME_NODE02


# Gere uma chave secreta para cada OSD, onde {$id}está o número do OSD:
mkdir -p /var/lib/ceph/osd/ceph-node01/keyring
ceph auth get-or-create osd.node03 mon 'allow rwx' osd 'allow *' -o /var/lib/ceph/osd/ceph-node01/keyring/osd.node03.keyring
ceph auth get-or-create osd.node04 mon 'allow rwx' osd 'allow *' -o /var/lib/ceph/osd/ceph-node01/keyring/osd.node04.keyring

# rules firewall
sudo iptables -A INPUT -p tcp --dport 6700:6900 -s 10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 6700:6900 -d 10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6 -j ACCEPT
sudo iptables -A INPUT -i eth0 -m multiport -p tcp -s 10.0.0.0/27 --dports 6800:7300 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4

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

# Configure the firewall settings for the current machine
for NODE in node01 node02 node03 node04 client
do
    ssh $NODE "firewall-cmd --add-service=ceph; firewall-cmd --runtime-to-permanent" -q
done


# VMs OSD configuration
NODES=("node03" "node04")
CEPH_CONF="/etc/ceph/ceph.conf"
ADMIN_KEYRING="/etc/ceph/ceph.client.admin.keyring"
OSD_KEYRING="/var/lib/ceph/bootstrap-osd/ceph.keyring"

# OSD MON CREATE PARTED DISK
chown ceph:ceph /etc/ceph/ceph.* /var/lib/ceph/bootstrap-osd/*
parted --script /dev/sdb 'mklabel gpt'
parted --script /dev/sdb 'mkpart primary 0% 100%'
ceph-volume lvm create --data /dev/sdb1

for NODE in node03 node04
do
    scp -o StrictHostKeyChecking=no $CEPH_CONF $NODE:/etc/ceph/
    scp -o StrictHostKeyChecking=no $ADMIN_KEYRING $NODE:/etc/ceph/
    scp -o StrictHostKeyChecking=no $OSD_KEYRING $NODE:/var/lib/ceph/bootstrap-osd/

    ssh -o StrictHostKeyChecking=no $NODE "
        chown ceph:ceph /etc/ceph/ceph.* /var/lib/ceph/bootstrap-osd/*; \
        parted --script /dev/sdb 'mklabel gpt'; \
        parted --script /dev/sdb 'mkpart primary 0% 100%'; \
        ceph-volume lvm create --data /dev/sdb1
    "
    MOUNTED=$(ssh -o StrictHostKeyChecking=no $NODE "mount | grep /dev/sdb1")

    if [ -n "$MOUNTED" ]; then
        echo "Partição montada em $NODE"
    else
        echo "Partição não está montada em $NODE"
    fi

    if [ $? -eq 0 ]; then
        echo "Tarefas concluídas com sucesso em $NODE"
    else
        echo "Erro ao executar tarefas em $NODE"
    fi
done

CLIENT_KEYRING="/etc/ceph/ceph.client.admin.keyring"
scp -o StrictHostKeyChecking=no $CLIENT_KEYRING $NODENAME_NODE02:/etc/ceph/
MGR_KEYRING="/etc/ceph/ceph.mgr.admin.keyring"
scp -o StrictHostKeyChecking=no $MGR_KEYRING $NODENAME_NODE02:/etc/ceph/


# crete dashboard ceph
ceph mgr module enable dashboard
ceph mgr module ls | grep dashboard
ceph dashboard create-self-signed-cert
echo "password" > pass.txt
ceph dashboard ac-user-create ceph -i pass.txt administrator
ceph mgr services


for NODE in node01 node02
 do
     if [ $NODE == "node01" ]; then
         firewall-cmd --add-port=8443/tcp
         firewall-cmd --runtime-to-permanent --quiet
     fi

     ssh $NODE "firewall-cmd --add-port=8443/tcp; firewall-cmd --runtime-to-permanent" -q
 done

systemctl daemon-reload
systemctl restart ceph-mgr@node02.service





# #Transfer SSH public key to Client Host and Configure it from Admin Node.

NODE_CLIENT=client
CEPH_CONF="/etc/ceph/ceph.conf"
DIRECTORY_MDS="/var/lib/ceph/mds/ceph-client/keyring"
ADMIN_KEYRING="/etc/ceph/ceph.client.admin.keyring"
ssh-copy-id -o StrictHostKeyChecking=no $NODE_CLIENT
# # create keyring MDS file
ssh-copy-id -o StrictHostKeyChecking=no $NODE_CLIENT
mkdir -p /var/lib/ceph/mds/ceph-$NODE_CLIENT
ceph-authtool --create-keyring /var/lib/ceph/mds/ceph-$NODE_CLIENT/keyring --gen-key -n mds.$NODE_CLIENT
chown -R ceph:ceph /var/lib/ceph/mds/ceph-$NODE_CLIENT
ceph auth add mds.$NODE_CLIENT osd "allow rwx" mds "allow" mon "allow profile mds" -i /var/lib/ceph/mds/ceph-$NODE_CLIENT/keyring

# # send conf ceph to client
while true; do
        scp $CEPH_CONF $NODE_CLIENT:/etc/ceph/
        scp $ADMIN_KEYRING $NODE_CLIENT:/etc/ceph/
        ssh $NODE_CLIENT "chown ceph:ceph /etc/ceph/"
        ssh $NODE_CLIENT "chomd 640 ADMIN_KEYRING"
        # scp $DIRECTORY_MDS $NODE_CLIENT:$DIRECTORY_MDS
     if [ $? -eq 0 ]; then
         echo "Comandos executados com sucesso."
         break
     else
         echo "Erro detectado. Tentando novamente em 5 segundos..."
         sleep 5
     fi
 done


# # create default RBD pool [rbd]
 while true; do
         ssh $NODE_CLIENT "
             ceph osd pool create rbd 32;\
             ceph osd pool set rbd pg_autoscale_mode on;\
             rbd pool init rbd;\
             ceph osd pool autoscale-status;\
             rbd create --size 10G --pool rbd rbd01;\
             rbd map rbd01;\
             rbd showmapped;\
             mkfs.xfs /dev/rbd0;\
             mount /dev/rbd0 /mnt;\
             df -hT;
         "
     if [ $? -eq 0 ]; then
         echo "Comandos executados com sucesso."
         break
     else
         echo "Erro detectado. Tentando novamente em 5 segundos..."
         sleep 5
     fi
 done

 for NODE in node01 node02 node03 node04 client
 do
     if [ $NODE == "node01" ]; then
          systemctl restart ceph-crash.service
          echo "Comandos executados com sucesso, $NODE. "
     fi
     ssh $NODE " systemctl restart ceph-crash.service"
        echo "Comandos executados com sucesso, $NODE. "

 done


 chown -R ceph. /var/lib/ceph/mds/ceph-$NODE_CLIENT
 systemctl enable --now ceph-mds@$NODE_CLIENT
 sudo chmod -R 644 /var/lib/ceph/mds/ceph-client/
 sudo chmod 755 /var/lib/ceph/mds/ceph-client/
 sudo chmod 755 /var/lib/ceph/mds/
 send command mgr to mds
 scp  $DIRECTORY_MDS $NODENAME_NODE02:$DIRECTORY_MDS
 sudo chown ceph:ceph $DIRECTORY_MDS
 chmod 640 /var/lib/ceph/mds/ceph-client/keyring
 sudo chown -R ceph:ceph /var/lib/ceph/mds/ceph-client



# # Configure a Client Host [client] to use Ceph Storage

 ceph osd pool create rbd_data 100
 ceph osd pool create rbd_metadata 16
 ceph fs new cephfs rbd_metadata rbd_data
 ceph osd pool set rbd_data pg_autoscale_bias 4
 ceph fs ls
 ceph mds stat
 ceph fs set cephfs max_mds 1

# #Create a Block device and mount it on a Client Host.
# # create default RBD pool [rbd]


# # Allow the MDS to go down and mark the filesystem offline
 ceph mds set allow_down true
 ceph mds set allow_new_snaps true
 ceph mds set allow_multimds true


# # send to client host executed keuring permmisions rwx-------

ssh $NODE_CLIENT "
    ceph-authtool -p /etc/ceph/ceph.client.admin.keyring > admin.key; \
    chmod 600 admin.key;
"
if [ $? -eq 0 ]; then
    echo "Remote command executed with success."
else
    echo "Err to remote command executed  Código de saída: $?"
fi

