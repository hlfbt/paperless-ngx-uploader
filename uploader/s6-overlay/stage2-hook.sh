#!/command/with-contenv /bin/bash

echo "Configuring s6 services..."

s6_rc_d=/etc/s6-overlay/s6-rc.d
contents_d=$s6_rc_d/user/contents.d
mkdir -p $contents_d 2>/dev/null

if [ "$API_UPLOADER_ENABLED" != "true" ]; then
    echo "Paperless API Uploader is disabled in configuration."
else
    touch $contents_d/paperless-uploader
fi

if [ "$API_UPLOADER_ONESHOT" != "true" ]; then
    echo "longrun" > $s6_rc_d/paperless-uploader/type
else
    echo "Paperless API Uploader Oneshot mode enabled in configuration."
    echo "oneshot" > $s6_rc_d/paperless-uploader/type
fi

if [ "$SAMBA_ENABLED" != "true" ]; then
    echo "Samba is disabled in configuration."
else
    touch $contents_d/samba
fi

if [ "$FTP_ENABLED" != "true" ]; then
    echo "FTP is disabled in configuration."
else
    touch $contents_d/vsftp
fi

if [ "$WEBDAV_ENABLED" != "true" ]; then
    echo "WebDAV is disabled in configuration."
else
    touch $contents_d/webdav
fi

if [ "$WSDD_ENABLED" != "true" ] || [ "$SAMBA_ENABLED" != "true" ]; then
    echo "WSDD is disabled in configuration or Samba is missing."
else
    touch $contents_d/wsdd
fi
