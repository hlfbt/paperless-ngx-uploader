#!/command/with-contenv /bin/bash

echo "Configuring Samba..."

# Create smb.conf
cat <<EOF > /etc/samba/smb.conf
[global]
   workgroup = WORKGROUP
   server string = Paperless Uploader
   security = user
   map to guest = Bad User
   dns proxy = no
   log file = /var/log/samba/log.%m
   max log size = 50
   load printers = no
   printing = bsd
   printcap name = /dev/null
   disable spoolss = yes

[paperless]
   path = $CONSUMPTION_DIR
   browsable = yes
   writable = yes
   guest ok = no
   valid users = $SAMBA_USER
   force user = paperless
   force group = paperless
   create mask = 0664
   directory mask = 0775
EOF

# Add Samba user
(echo "$SAMBA_PASS"; echo "$SAMBA_PASS") | smbpasswd -a -s "$SAMBA_USER" || (useradd -M -s /sbin/nologin "$SAMBA_USER" && (echo "$SAMBA_PASS"; echo "$SAMBA_PASS") | smbpasswd -a -s "$SAMBA_USER")

echo "Samba configured for user $SAMBA_USER."
