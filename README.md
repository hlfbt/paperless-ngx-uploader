# Paperless-NGX Uploader

This Docker image provides an automatic file uploader for `paperless-ngx` via Samba, FTP, and WebDAV, as well as an API-based uploader for remote instances. It's designed to be a single container running multiple services managed by `s6-overlay`.

## Features
- **Samba (SMB) Server**: Standard network share for easy drag-and-drop.
- **FTP Server**: Legacy and automated file transfer support.
- **WebDAV Server**: Modern HTTP-based file transfer support (port 8080).
- **Windows Discovery (WSDD)**: Ensures the share shows up in Windows Explorer.
- **API Uploader**: Automatically monitors the consumption directory and uploads files to a remote Paperless-ngx instance via API.
- **Oneshot Mode**: Option to run a single scan and exit, perfect for scheduled tasks.
- **Fully Configurable**: All services can be enabled/disabled and configured via environment variables.
- **Permissions Support**: Handles `PUID` and `PGID` to match your host system's user permissions.

## Image Flavors

The image is available in two flavors:

- `full` (default): Contains all services (Samba, FTP, WebDAV, API Uploader) and is managed by `s6-overlay`.
- `lightweight`: Minimal image containing only the API Uploader and its dependencies (inotify-tools, curl). Does not include `s6-overlay` or any services.

To build a specific flavor:
```bash
docker build --build-arg FLAVOR=lightweight -t uploader:lightweight uploader/
```

| Variable | Default | Description | Lightweight |
|----------|---------|-------------|-------------|
| `SAMBA_ENABLED` | `true` | Set to `false` to disable Samba (also disables WSDD). | |
| `SAMBA_USER` | `paperless` | Username for Samba. | |
| `SAMBA_PASS` | `paperless` | Password for Samba. | |
| `FTP_ENABLED` | `true` | Set to `false` to disable FTP. | |
| `FTP_USER` | `paperless` | Username for FTP. | |
| `FTP_PASS` | `paperless` | Password for FTP. | |
| `WEBDAV_ENABLED` | `true` | Set to `false` to disable WebDAV. | |
| `WEBDAV_USER` | `paperless` | Username for WebDAV (Digest Auth). | |
| `WEBDAV_PASS` | `paperless` | Password for WebDAV. | |
| `WEBDAV_PORT` | `8080` | Port for WebDAV server. | |
| `PASV_ADDRESS` | | Host IP for FTP passive mode. Required if behind NAT. | |
| `PASV_MIN_PORT` | `21100` | Start of passive port range. | |
| `PASV_MAX_PORT` | `21110` | End of passive port range. | |
| `WSDD_ENABLED` | `true` | Set to `false` to disable Windows Discovery. | |
| `API_UPLOADER_ENABLED` | `true` | Set to `false` to disable the Paperless API uploader. Note: has no effect in lightweight flavor. | |
| `API_UPLOADER_ON_SUCCESS` | `delete` | Action after success: `delete`, `archive`, or `none`. | ✔ |
| `API_UPLOADER_ONESHOT` | `false` | If `true`, the container will exit after a single scan. | ✔ |
| `PAPERLESS_URL` | | URL of your Paperless-ngx instance (e.g., `https://paperless.example.com`). | ✔ |
| `PAPERLESS_TOKEN` | | API Token from your Paperless profile. | ✔ |
| `PUID` | `1000` | User ID for file ownership. | ✔ |
| `PGID` | `1000` | Group ID for file ownership. | ✔ |
| `CONSUMPTION_DIR` | `/consumption` | Path inside container where files go. | ✔ |
| `ARCHIVE_DIR` | `/archive` | Path to store archived files if `archive` action is selected. | ✔ |
| `CONSUMPTION_FILTER` | | Regular Expression to filter consumed files. Files not matching the filter will be skipped. Not: hidden files (starting with a `.`) are always skipped. | ✔ |

## Quick Start with Docker Compose

1. Create a `docker-compose.yml` (example provided in repository).
2. Start the uploader:
   ```bash
   docker-compose up -d
   ```
3. Your services will be available at:
   - **Samba**: `\\<host-ip>\paperless` / `smb://<host-ip>/paperless`
   - **FTP**: `ftp://<host-ip>:21`
   - **WebDAV**: `http://<host-ip>:8080`

## Quick Start with Docker Run

### Run all services
```bash
docker run -d \
  --name uploader \
  -v /path/to/consume:/consumption \
  -p 137-139:137-139/udp \
  -p 445:445 \
  -p 21:21 \
  -p 21100-21110:21100-21110 \
  -p 8080:8080 \
  -e SAMBA_PASS=yourpassword \
  -e FTP_PASS=yourpassword \
  ghcr.io/hlfbt/paperless-ngx-uploader:latest
```

### Run as a one-shot uploader (Lightweight)
This example scans a local directory, uploads everything to the Paperless-ngx API, and exits:
```bash
docker run --rm \
  -v /path/to/docs:/consumption \
  -e API_UPLOADER_ONESHOT=true \
  -e PAPERLESS_URL=https://paperless.example.com \
  -e PAPERLESS_TOKEN=your_token_here \
  ghcr.io/hlfbt/paperless-ngx-uploader:lightweight
```

## Integration with Paperless-NGX

### Method 1: Local Shared Volume
Mount the same host directory to both this uploader's `/consumption` and `paperless-ngx`'s `PAPERLESS_CONSUMPTION_DIR`. This is the most efficient method for local setups.

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

### Method 2: API Upload (Remote or Isolated)
Enable the API Uploader to have this container push files to Paperless-ngx via the REST API. This is useful if the containers are on different hosts or if you don't want to manage shared volume permissions.

```yaml
services:
  uploader:
    # ...
    environment:
      - PAPERLESS_URL=http://paperless-ngx:8000
      - PAPERLESS_TOKEN=your_api_token
    volumes:
      - /mnt/paperless/consume:/consumption
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
