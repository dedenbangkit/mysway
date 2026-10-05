#!/bin/sh
# Install the Ollama service override and restart it. Run with sudo.
set -e
cd "$(dirname "$0")"
install -Dm644 override.conf /etc/systemd/system/ollama.service.d/override.conf
systemctl daemon-reload
systemctl restart ollama
systemctl --no-pager --lines=0 status ollama
