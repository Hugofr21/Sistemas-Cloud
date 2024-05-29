curl -o api-spring.zip https://storage.googleapis.com/bucket-cloud-api/api-spring.zip
unzip api-spring.zip

named-checkconf /etc/named.conf
named-checkzone video.world /var/named/video.world.db
named-checkzone 10.0.16.172.in-addr.arpa /var/named/10.0.16.172.db

dig @35.246.193.214 video22.world A
dig @35.246.193.214 www.video22.world A
dig @35.246.193.214 -x 172.16.0.10

sudo nano /etc/firewalld/firewalld.conf
# AllowZoneDrifting=no
sudo systemctl restart firewalld


blog.video22.world
www.video22.world
ns1.video22.world