#!/bin/bash

if ! lsblk -f /dev/nvme1n1 | grep unifi-data >/dev/null 2>&1; then
  mkfs -t ext4 -L unifi-data /dev/nvme1n1
fi

mkdir /var/lib/unifi
echo -e LABEL=unifi-data\\t/var/lib/unifi ext4 defaults,nofail 0 2 >> /etc/fstab

cat >/etc/default/unifi << 'EOF'
JVM_MAX_HEAP_SIZE=64M
EOF

dd if=/dev/zero of=/swapfile bs=1M count=1024
mkswap /swapfile
chmod 600 /swapfile
echo -e /swapfile\\t swap swap defaults 0 0 >> /etc/fstab

systemctl daemon-reload
mount /var/lib/unifi
swapon -a

export DEBIAN_FRONTEND=noninteractive

echo "deb http://www.ubnt.com/downloads/unifi/debian stable ubiquiti" | \
  tee -a /etc/apt/sources.list

apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50

apt-get update

apt install -q -y unifi openjdk-8-jre-headless python-certbot-nginx

cat >/etc/nginx/sites-available/default << 'EOF'
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /var/www/html;

	index index.html;

	server_name ${server_name};

	location / {
		try_files $uri $uri/ =404;
	}
}
EOF

cat >/var/lib/unifi/rotate-keystore.sh << 'EOF'
#!/bin/bash
PASS=aircontrolenterprise
PRIVKEY=/etc/letsencrypt/live/${server_name}/privkey.pem
CHAIN=/etc/letsencrypt/live/${server_name}/fullchain.pem
KEYHASH=/var/lib/unifi/letsencrypt.md5

if md5sum -c $KEYHASH &>/dev/null; then
    # MD5 remains unchanged, exit the script
    printf "\nCertificate is unchanged, no update is necessary.\n"
    exit 0
fi

P12_TEMP=$(mktemp)

function cleanup {
  rm -rf "$P12_TEMP"
}

trap cleanup EXIT

openssl pkcs12 -export \
    -in $CHAIN \
    -inkey $PRIVKEY \
    -name unifi \
    -out $P12_TEMP \
    -passout pass:$PASS

keytool -importkeystore \
    -srckeystore $P12_TEMP \
    -srcstoretype PKCS12 \
    -srcstorepass $PASS \
    -destkeystore /var/lib/unifi/keystore \
    -deststorepass $PASS \
    -noprompt \
    -trustcacerts

md5sum $PRIVKEY > $KEYHASH

service unifi restart
EOF

chmod 755 /var/lib/unifi/rotate-keystore.sh

cat >/etc/cron.d/unifi-keystore << 'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 * * * 4 root /var/lib/unifi/rotate-keystore.sh
EOF

certbot --nginx -d ${server_name} -m ${admin_email} --non-interactive --agree-tos

/var/lib/unifi/rotate-keystore.sh
