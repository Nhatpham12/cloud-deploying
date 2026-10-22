#!/bin/bash
# Run ONCE on a fresh Amazon Linux 2023 EC2 instance (or paste into "User data").
set -e
sudo dnf install -y docker rsync
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
# Docker Compose v2 plugin
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
mkdir -p ~/app
echo "Done. Log out and back in so the docker group takes effect."
