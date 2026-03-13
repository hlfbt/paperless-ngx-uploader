# Paperless-NGX Uploader

This Docker image provides an automatic file uploader for `paperless-ngx` via Samba and FTP. It's designed to be a single container running multiple services managed by `s6-overlay`.

## Features
- **Samba (SMB) Server**: Standard network share for easy drag-and-drop.
- **FTP Server**: Legacy and automated file transfer support.
- **WebDAV Server**: Modern HTTP-based file transfer support (port 8080).
- **Windows Discovery (WSDD)**: Ensures the share shows up in Windows Explorer.
- **API Uploader**: Automatically monitors the consumption directory and uploads files to a remote Paperless-ngx instance via API.
- **Oneshot Mode**: Option to run a single scan and exit, perfect for scheduled tasks.
- **Fully Configurable**: All services can be enabled/disabled and configured via environment variables.
- **Permissions Support**: Handles `PUID` and `PGID` to match your host system's user permissions.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SAMBA_ENABLED` | `true` | Set to `false` to disable Samba. |
| `SAMBA_USER` | `paperless` | Username for Samba. |
| `SAMBA_PASS` | `paperless` | Password for Samba. |
| `FTP_ENABLED` | `true` | Set to `false` to disable FTP. |
| `FTP_USER` | `paperless` | Username for FTP. |
| `FTP_PASS` | `paperless` | Password for FTP. |
| `WEBDAV_ENABLED` | `true` | Set to `false` to disable WebDAV. |
| `WEBDAV_USER` | `paperless` | Username for WebDAV (Digest Auth). |
| `WEBDAV_PASS` | `paperless` | Password for WebDAV. |
| `WEBDAV_PORT` | `8080` | Port for WebDAV server. |
| `PASV_ADDRESS` | | Host IP for FTP passive mode. Required if behind NAT. |
| `PASV_MIN_PORT` | `21100` | Start of passive port range. |
| `PASV_MAX_PORT` | `21110` | End of passive port range. |
| `WSDD_ENABLED` | `true` | Set to `false` to disable Windows Discovery. |
| `API_UPLOADER_ENABLED` | `false` | Set to `true` to enable the API uploader. |
| `API_UPLOADER_ON_SUCCESS` | `delete` | Action after success: `delete` or `archive`. |
| `API_UPLOADER_ONESHOT` | `false` | If `true`, the container will exit after a single scan. |
| `ARCHIVE_DIR` | `/archive` | Path to store archived files if `archive` is selected. |
| `PAPERLESS_URL` | | URL of your Paperless-ngx instance (e.g., `https://paperless.example.com`). |
| `PAPERLESS_TOKEN` | | API Token from your Paperless profile. |
| `PUID` | `1000` | User ID for file ownership. |
| `PGID` | `1000` | Group ID for file ownership. |
| `CONSUMPTION_DIR` | `/consumption` | Path inside container where files go. |

## Quick Start with Docker Compose

1. Create a `docker-compose.yml` (example provided in repository).
2. Start the uploader:
   ```bash
   docker-compose up -d
   ```
3. Your Samba share will be available at `\\<host-ip>\paperless`.
4. Your FTP server will be available at `ftp://<host-ip>:21`.

## Integration with Paperless-NGX

Mount the same host directory to both this uploader's `/consumption` and `paperless-ngx`'s `PAPERLESS_CONSUMPTION_DIR`.

```yaml
services:
  uploader:
    # ...
    volumes:
      - /mnt/paperless/consume:/consumption
  
  paperless:
    # ...
    volumes:
      - /mnt/paperless/consume:/usr/src/paperless/consume
```

## Testing

The project includes both state and integration tests.

### State Tests
Uses [Google Container Structure Tests](https://github.com/GoogleContainerTools/container-structure-test) to verify the internal configuration of the image.

To run:
```bash
docker build -t uploader:latest ./uploader
container-structure-test test --image uploader:latest --config tests/structure-tests.yaml
```

### Integration Tests
Uses a mock API and Docker Compose to verify the end-to-end flow.

To run:
```bash
./tests/run-integration-tests.sh
```
This will:
1. Build the image.
2. Start a mock Paperless API.
3. Verify that files added to the consumption directory are uploaded correctly and handled according to the `API_UPLOADER_ON_SUCCESS` setting (delete or archive).
