#!/usr/bin/with-contenv bash

if [ "$FTP_ENABLED" != "true" ]; then
    echo "FTP is disabled."
    exit 0
fi

echo "Configuring vsftpd..."

# Configure vsftpd
cat <<EOF > /etc/vsftpd/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=002
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO

# Passive mode configuration
pasv_enable=YES
pasv_min_port=$PASV_MIN_PORT
pasv_max_port=$PASV_MAX_PORT
EOF

if [ -n "$PASV_ADDRESS" ]; then
    echo "pasv_address=$PASV_ADDRESS" >> /etc/vsftpd/vsftpd.conf
    echo "pasv_addr_resolve=YES" >> /etc/vsftpd/vsftpd.conf
fi

# Ensure user exists for FTP (should be created by 01-config-users.sh or custom user)
if ! getent passwd "$FTP_USER" > /dev/null; then
    useradd -m -s /bin/bash "$FTP_USER"
fi
echo "$FTP_USER:$FTP_PASS" | chpasswd

# Point user home directory to consumption dir
usermod -d "$CONSUMPTION_DIR" "$FTP_USER"

# Required directory for vsftpd
mkdir -p /var/run/vsftpd/empty

echo "FTP configured for user $FTP_USER."
