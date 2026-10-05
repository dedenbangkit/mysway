#!/bin/sh
# Link the Ollama user service (no sudo). It is deliberately not enabled:
# ai-chat and summarize start it when needed.
set -e
mkdir -p ~/.config/systemd/user
ln -sf "$(realpath "$(dirname "$0")")/ollama.service" ~/.config/systemd/user/ollama.service
systemctl --user daemon-reload
echo "Linked. Start: systemctl --user start ollama   Stop: stop-ollama"
