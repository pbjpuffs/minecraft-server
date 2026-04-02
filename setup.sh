#!/bin/bash
set -euo pipefail

echo "========================================="
echo "  Minecraft Server Setup for Ubuntu"
echo "========================================="

# Update system
echo "[1/5] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "[2/5] Installing Docker..."
    sudo apt install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings

    # Remove ALL conflicting Docker keys and source lists
    sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/docker.asc
    sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources

    # Add fresh key and source (single canonical path)
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    echo "  Docker installed. You may need to log out and back in for group changes."
else
    echo "[2/5] Docker already installed, skipping."
fi

# Install Docker Compose plugin if not present
if ! docker compose version &> /dev/null; then
    echo "[3/5] Installing Docker Compose plugin..."
    sudo apt install -y docker-compose-plugin
else
    echo "[3/5] Docker Compose already installed, skipping."
fi

# Configure firewall
echo "[4/5] Configuring firewall..."
sudo ufw allow 25565/tcp comment "Minecraft Server"
sudo ufw allow 22/tcp comment "SSH"
sudo ufw --force enable
echo "  Firewall configured: port 25565 (Minecraft) and 22 (SSH) open."

# Create directories
echo "[5/5] Creating directories..."
mkdir -p data/plugins
chmod +x backup.sh install-plugins.sh

echo ""
echo "========================================="
echo "  Setup complete!"
echo "========================================="
echo ""
echo "IMPORTANT: Edit docker-compose.yml and change RCON_PASSWORD before starting!"
echo ""
echo "Commands:"
echo "  Start server:    docker compose up -d"
echo "  View logs:       docker compose logs -f"
echo "  Stop server:     docker compose down"
echo "  Server console:  docker attach minecraft-server  (Ctrl+P, Ctrl+Q to detach)"
echo "  RCON console:    docker exec -i minecraft-server rcon-cli"
echo ""
echo "Players connect to: <YOUR_SERVER_IP>:25565"
echo ""
