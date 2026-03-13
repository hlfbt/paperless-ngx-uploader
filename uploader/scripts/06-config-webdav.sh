#!/bin/bash

if [ "$WEBDAV_ENABLED" != "true" ]; then
    echo "WebDAV is disabled."
    exit 0
fi

echo "Configuring WebDAV..."

# Configure lighttpd for WebDAV
REALM="Paperless WebDAV"
WEBDAV_HTDIGEST_FILE="/etc/lighttpd/webdav.htdigest"

# Create lighttpd configuration
cat <<EOF > /etc/lighttpd/lighttpd.conf
server.modules = (
    "mod_access",
    "mod_alias",
    "mod_redirect",
    "mod_webdav",
    "mod_auth",
    "mod_authn_file"
)

server.document-root = "$CONSUMPTION_DIR"
server.port = $WEBDAV_PORT
server.username = "paperless"
server.groupname = "paperless"

# Fix for some WebDAV clients
dir-listing.activate = "enable"
server.dir-listing = "enable"

\$HTTP["url"] =~ "^/" {
    webdav.activate = "enable"
    webdav.is-readonly = "disable"
    # sqlite database for locking
    webdav.sqlite-db-name = "/var/run/lighttpd/webdav.db"
    
    auth.backend = "htdigest"
    auth.backend.htdigest.userfile = "$WEBDAV_HTDIGEST_FILE"
    auth.require = ( "" => (
        "method" => "digest",
        "realm" => "$REALM",
        "require" => "valid-user"
    ) )
}

# Standard error logging
server.errorlog = "/dev/stderr"
EOF

# Create the htdigest file
HASH=$(echo -n "$WEBDAV_USER:$REALM:$WEBDAV_PASS" | md5sum | cut -f1 -d' ')
echo "$WEBDAV_USER:$REALM:$HASH" > "$WEBDAV_HTDIGEST_FILE"
chown paperless:paperless "$WEBDAV_HTDIGEST_FILE"
chmod 600 "$WEBDAV_HTDIGEST_FILE"

# Required directory for lighttpd
mkdir -p /var/run/lighttpd
chown paperless:paperless /var/run/lighttpd

echo "WebDAV configured for user $WEBDAV_USER on port $WEBDAV_PORT."
