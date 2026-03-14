# Global ARGs for build metadata
ARG FLAVOR=full
ARG SAMBA_VERSION="unknown"
ARG VSFTPD_VERSION="unknown"
ARG WSDD_VERSION="unknown"
ARG LIGHTTPD_VERSION="unknown"
ARG S6_OVERLAY_VERSION=3.2.2.0
ARG BUILD_DATE="unknown"
ARG REPO_REF="unknown"
ARG REPO_COMMIT="unknown"
ARG GITHUB_REPOSITORY="unknown"

# Stage 1: Base image with common dependencies and configuration
FROM alpine:3.19 AS base
ARG FLAVOR

# Install base dependencies
RUN apk add --no-cache \
    bash \
    shadow \
    inotify-tools \
    curl \
    findutils

# Create default consumption and archive directories
RUN mkdir -p /consumption /archive && \
    chmod -R 775 /consumption /archive

# Copy and prepare scripts
COPY bin/ /usr/local/bin/

# Copy s6-overlay configuration (some scripts are required in both flavors)
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
    API_UPLOADER_ENABLED=true \
    API_UPLOADER_ON_SUCCESS=delete \
    API_UPLOADER_ONESHOT=false \
    PAPERLESS_URL= \
    PAPERLESS_TOKEN= \
    PUID=1000 \
    PGID=1000 \
    PASV_ADDRESS= \
    PASV_MIN_PORT=21100 \
    PASV_MAX_PORT=21110 \
    CONSUMPTION_DIR=/consumption \
    ARCHIVE_DIR=/archive \
    CONSUMPTION_FILTER= \
    FLAVOR=${FLAVOR}


# Stage 2a: Flavor-full (Samba, FTP, WebDAV, WSDD, orchestrated with s6-overlay)
FROM base AS flavor-full
ARG SAMBA_VERSION
ARG VSFTPD_VERSION
ARG WSDD_VERSION
ARG LIGHTTPD_VERSION
ARG S6_OVERLAY_VERSION
ARG REPO_REF
ARG REPO_COMMIT
ARG BUILD_DATE
ARG GITHUB_REPOSITORY

LABEL org.opencontainers.image.title="Paperless-NGX Uploader (Full)" \
      org.opencontainers.image.description="Paperless-NGX Uploader (Samba ${SAMBA_VERSION}, vsftpd ${VSFTPD_VERSION}, wsdd ${WSDD_VERSION}, WebDAV ${LIGHTTPD_VERSION}) - ${REPO_REF}@${REPO_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${REPO_COMMIT}" \
      org.opencontainers.image.source="https://github.com/${GITHUB_REPOSITORY}" \
      com.paperless_uploader.flavor="full" \
      com.paperless_uploader.samba_version="${SAMBA_VERSION}" \
      com.paperless_uploader.vsftpd_version="${VSFTPD_VERSION}" \
      com.paperless_uploader.wsdd_version="${WSDD_VERSION}" \
      com.paperless_uploader.lighttpd_version="${LIGHTTPD_VERSION}"

# Install full toolset packages and s6-overlay
RUN apk add --no-cache \
        tar \
        xz \
        samba \
        vsftpd \
        wsdd \
        lighttpd \
        lighttpd-mod_webdav \
        lighttpd-mod_auth \
        sqlite && \
    curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz | tar -Jxpf - -C / && \
    curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz | tar -Jxpf - -C /

# Add s6-overlay stage 2 hook that dynamically configures the s6 services
ENV S6_STAGE2_HOOK=/etc/s6-overlay/stage2-hook.sh

# Expose ports for Samba, FTP, WebDAV, and WSDD
EXPOSE 445/tcp 137/udp 138/udp 139/tcp 21/tcp 21100-21110/tcp 8080/tcp 3702/udp 5357/tcp

# Use s6-overlay init
ENTRYPOINT ["/init"]


# Stage 2b: Flavor-lightweight (API Uploader only)
FROM base AS flavor-lightweight
ARG REPO_REF
ARG REPO_COMMIT
ARG BUILD_DATE
ARG GITHUB_REPOSITORY

LABEL org.opencontainers.image.title="Paperless-NGX Uploader (Lightweight)" \
      org.opencontainers.image.description="Paperless-NGX Uploader (Lightweight API Uploader) - ${REPO_REF}@${REPO_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${REPO_COMMIT}" \
      org.opencontainers.image.source="https://github.com/${GITHUB_REPOSITORY}" \
      com.paperless_uploader.flavor="lightweight"

# Set ENTRYPOINT to the lightweight entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint-lightweight.sh"]


# Stage 3: Final image selection based on FLAVOR argument
FROM flavor-${FLAVOR} AS final
