FROM alpine:3.19

# Set s6-overlay version
ARG S6_OVERLAY_VERSION=3.2.2.0

# Build metadata
ARG SAMBA_VERSION="unknown"
ARG VSFTPD_VERSION="unknown"
ARG WSDD_VERSION="unknown"
ARG LIGHTTPD_VERSION="unknown"
ARG BUILD_DATE="unknown"
ARG REPO_REF="unknown"
ARG REPO_COMMIT="unknown"
ARG GITHUB_REPOSITORY="unknown"

LABEL org.opencontainers.image.title="Paperless-NGX Uploader" \
      org.opencontainers.image.description="Paperless-NGX Uploader (Samba ${SAMBA_VERSION}, vsftpd ${VSFTPD_VERSION}, wsdd ${WSDD_VERSION}, WebDAV ${LIGHTTPD_VERSION}) - ${REPO_REF}@${REPO_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${REPO_COMMIT}" \
      org.opencontainers.image.source="https://github.com/${GITHUB_REPOSITORY}" \
      com.paperless_uploader.samba_version="${SAMBA_VERSION}" \
      com.paperless_uploader.vsftpd_version="${VSFTPD_VERSION}" \
      com.paperless_uploader.wsdd_version="${WSDD_VERSION}" \
      com.paperless_uploader.lighttpd_version="${LIGHTTPD_VERSION}"

# Install necessary packages for extraction and initial setup
RUN apk add --no-cache curl tar xz

# Install s6-overlay
RUN curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz | tar -Jxpf - -C / && \
    curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz | tar -Jxpf - -C /

# Install application packages
RUN apk add --no-cache \
    samba \
    vsftpd \
    wsdd \
    lighttpd \
    lighttpd-mod_webdav \
    lighttpd-mod_auth \
    sqlite \
    bash \
    shadow \
    inotify-tools

# Create consumption directory
RUN mkdir -p /consumption && chmod 777 /consumption

# Copy scripts and s6-overlay configuration
COPY scripts/ /etc/cont-init.d/
COPY s6-overlay/ /etc/s6-overlay/

# Set environment variables with defaults
ENV SAMBA_ENABLED=true \
    SAMBA_USER=paperless \
    SAMBA_PASS=paperless \
    FTP_ENABLED=true \
    FTP_USER=paperless \
    FTP_PASS=paperless \
    WEBDAV_ENABLED=true \
    WEBDAV_USER=paperless \
    WEBDAV_PASS=paperless \
    WEBDAV_PORT=8080 \
    WSDD_ENABLED=true \
    API_UPLOADER_ENABLED=false \
    API_UPLOADER_ON_SUCCESS=delete \
    ARCHIVE_DIR=/archive \
    PAPERLESS_URL= \
    PAPERLESS_TOKEN= \
    PUID=1000 \
    PGID=1000 \
    CONSUMPTION_DIR=/consumption \
    PASV_ADDRESS= \
    PASV_MIN_PORT=21100 \
    PASV_MAX_PORT=21110

# Expose ports
# Samba: 445 (TCP), 137/138 (UDP), 139 (TCP)
# FTP: 21 (TCP), 21100-21110 (TCP for passive mode)
# WebDAV: 8080 (TCP)
# WSDD: 3702 (UDP), 5357 (TCP)
EXPOSE 445/tcp 137/udp 138/udp 139/tcp 21/tcp 21100-21110/tcp 8080/tcp 3702/udp 5357/tcp

ENTRYPOINT ["/init"]
