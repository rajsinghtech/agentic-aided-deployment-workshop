#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl docker.io
curl -fsSL https://tailscale.com/install.sh | sh

useradd --create-home --shell /bin/bash deploy || true
usermod -aG docker deploy
install -d -o deploy -g deploy -m 0755 /home/deploy/bin
curl -fsS -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/activate-workshop-release \
  -o /home/deploy/bin/activate-workshop-release
chown deploy:deploy /home/deploy/bin/activate-workshop-release
chmod 0755 /home/deploy/bin/activate-workshop-release

systemctl enable --now docker
systemctl enable --now tailscaled

if ! tailscale status --json | grep -q '"BackendState": "Running"'; then
  tailscale up \
    --auth-key="__TS_AUTH_KEY__" \
    --hostname=agentic-workshop-host \
    --advertise-tags=tag:demo-host \
    --ssh \
    --accept-dns=false \
    --accept-routes=false
fi

tailscale set --ssh --accept-dns=false --accept-routes=false --auto-update

tailscale serve --service=svc:workshop-app --https=443 127.0.0.1:3000
tailscale serve status --json > /var/log/workshop-service.json
