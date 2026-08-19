#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Building Docker image..."
docker build -t py39-pack .

echo "==> Extracting py39.tgz..."
docker run --rm -v "$SCRIPT_DIR":/output py39-pack

echo "==> Done! py39.tgz is at: $SCRIPT_DIR/py39.tgz"