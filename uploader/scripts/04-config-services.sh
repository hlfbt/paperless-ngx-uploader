#!/command/with-contenv /bin/bash

# This script runs during the initialization phase (cont-init.d)
# and can be used to dynamically enable/disable s6-rc services.
# However, s6-rc is initialized before cont-init.d in v3.
# So the run script check is the most reliable way for simple setups.

if [ "$SAMBA_ENABLED" != "true" ]; then
    echo "Samba is disabled in configuration."
fi

if [ "$FTP_ENABLED" != "true" ]; then
    echo "FTP is disabled in configuration."
fi

if [ "$WSDD_ENABLED" != "true" ]; then
    echo "WSDD is disabled in configuration."
fi
