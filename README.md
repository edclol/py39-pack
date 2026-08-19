# py39-pack

Build a portable Python 3.9 conda environment packaged as `py39.tgz`, based on CentOS 7, delivered via Docker image to GHCR.

## Usage

### Pull the image

```bash
docker pull ghcr.io/edclol/py39-pack
```

### Extract py39.tgz

**Option 1 — Bind mount a volume:**
```bash
docker run --rm -v $(pwd):/output ghcr.io/edclol/py39-pack
# → py39.tgz appears in current directory
```

**Option 2 — Stream to stdout:**
```bash
docker run --rm ghcr.io/edclol/py39-pack > py39.tgz
```

### Deploy the tgz to a server

```bash
# On the target server
mkdir -p /data/soft/py39
tar -xzf py39.tgz -C /data/soft/py39
source /data/soft/py39/bin/activate
```

## What's inside

- Python 3.9.20 (via conda)
- Packages: pandas, numpy, fastapi, uvicorn, SQLAlchemy, psycopg2, pymysql, pyodbc, jaydebeapi, cryptography, requests, httpx, matplotlib, scipy, and more (see `req.txt`)

## Build locally

```bash
docker build -t py39-pack .
docker run --rm -v $(pwd):/output py39-pack
```

## GitHub Container Registry

Push to your GitHub repo → GitHub Actions automatically builds and pushes to `ghcr.io/edclol/py39-pack`.