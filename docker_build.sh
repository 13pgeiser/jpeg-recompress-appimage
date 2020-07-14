#!/bin/bash
set -e
docker rm -f jpeg-archive || true
docker build -t jpeg-archive .
docker run --rm --entrypoint cat jpeg-archive /jpeg-recompress-x86_64.AppImage > jpeg-recompress-x86_64.AppImage
chmod +x ./jpeg-recompress-x86_64.AppImage
