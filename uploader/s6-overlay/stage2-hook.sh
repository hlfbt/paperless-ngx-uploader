#!/command/with-contenv /bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

echo "Configuring s6 services..."

s6_rc_d=/etc/s6-overlay/s6-rc.d
contents_d=$s6_rc_d/user/contents.d
mkdir -p $contents_d 2>/dev/null

echo -n "Paperless API Uploader: "
if [ "$API_UPLOADER_ENABLED" != "true" ]; then
    echo -n "${MAGENTA}disabled${NC}"
else
    echo -n "${GREEN}enabled${NC}"
    touch $contents_d/paperless-uploader
fi

if [ "$API_UPLOADER_ONESHOT" != "true" ]; then
    echo " ${GRAY}(inotify)${NC}"
    echo "longrun" > $s6_rc_d/paperless-uploader/type
else
    echo " ${CYAN}(oneshot)${NC}"
    echo "oneshot" > $s6_rc_d/paperless-uploader/type
fi

echo -n "Samba: "
if [ "$SAMBA_ENABLED" != "true" ]; then
    echo "Samba is disabled in configuration."
    echo "${MAGENTA}disabled${NC}"
else
    echo "${GREEN}enabled${NC}"
    touch $contents_d/samba
fi

echo -n "FTP: "
if [ "$FTP_ENABLED" != "true" ]; then
    echo "${MAGENTA}disabled${NC}"
else
    echo "${GREEN}enabled${NC}"
    touch $contents_d/vsftpd
fi

echo -n "WebDAV: "
if [ "$WEBDAV_ENABLED" != "true" ]; then
    echo "${MAGENTA}disabled${NC}"
else
    echo "${GREEN}enabled${NC}"
    touch $contents_d/webdav
fi

echo -n "WSDD: "
if [ "$WSDD_ENABLED" != "true" ] || [ "$SAMBA_ENABLED" != "true" ]; then
    echo "${MAGENTA}disabled${NC}"
else
    echo "${GREEN}enabled${NC}"
    touch $contents_d/wsdd
fi
