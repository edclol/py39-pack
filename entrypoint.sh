#!/bin/bash
set -e

if [ -d "/output" ]; then
    # Bind-mount a volume: docker run --rm -v $(pwd):/output ghcr.io/<user>/py39-pack
    cp /py39.tgz /output/
    echo "✅ py39.tgz copied to /output/"
else
    # Stream to stdout: docker run --rm ghcr.io/<user>/py39-pack > py39.tgz
    cat /py39.tgz
fi