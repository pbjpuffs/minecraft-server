#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo -e "${RED}=========================================${NC}"
echo -e "${RED}  Minecraft Server - Complete Uninstall${NC}"
echo -e "${RED}=========================================${NC}"
echo ""
echo "This will remove:"
echo "  1. Stop and remove the Minecraft Docker container"
echo "  2. Remove the Minecraft Docker image"
echo "  3. Remove all server data (world, plugins, configs)"
echo "  4. Remove all backups"
echo "  5. Remove the backup cron job"
echo "  6. Remove the firewall rule for port 25565"
echo "  7. Optionally uninstall Docker entirely"
echo ""
echo -e "${YELLOW}WARNING: This is irreversible. All world data will be lost.${NC}"
echo ""
read -rp "Create a final backup before uninstalling? [Y/n]: " DO_BACKUP
DO_BACKUP=${DO_BACKUP:-Y}

if [[ "$DO_BACKUP" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}[backup]${NC} Creating final backup..."
    BACKUP_DIR="./backups"
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    FINAL_BACKUP="${BACKUP_DIR}/minecraft_FINAL_backup_${TIMESTAMP}.tar.gz"

    # Try graceful save if server is running
    docker exec minecraft-server rcon-cli save-all 2>/dev/null && sleep 3 || true

    if [ -d "./data" ]; then
        tar -czf "$FINAL_BACKUP" -C ./data .
        echo -e "${GREEN}[backup]${NC} Final backup saved to: $FINAL_BACKUP"
        echo ""
        read -rp "Copy backup to another location before continuing? Enter path or press Enter to skip: " COPY_PATH
        if [ -n "$COPY_PATH" ]; then
            cp "$FINAL_BACKUP" "$COPY_PATH/"
            echo -e "${GREEN}[backup]${NC} Backup copied to: $COPY_PATH/"
        fi
    else
        echo -e "${YELLOW}[backup]${NC} No data directory found, skipping backup."
    fi
fi

echo ""
read -rp "Are you sure you want to uninstall everything? Type 'yes' to confirm: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""

# 1. Stop and remove container
echo -e "${RED}[1/7]${NC} Stopping and removing Minecraft container..."
docker compose down --volumes 2>/dev/null || true
docker rm -f minecraft-server 2>/dev/null || true
echo "  Done."

# 2. Remove Docker image
echo -e "${RED}[2/7]${NC} Removing Minecraft Docker image..."
docker rmi itzg/minecraft-server:latest 2>/dev/null || true
echo "  Done."

# 3. Remove server data
echo -e "${RED}[3/7]${NC} Removing server data..."
if [ -d "./data" ]; then
    rm -rf ./data
    echo "  Removed ./data/"
else
    echo "  No data directory found."
fi

# 4. Remove backups
echo ""
read -rp "Also remove all backups in ./backups/? [y/N]: " REMOVE_BACKUPS
REMOVE_BACKUPS=${REMOVE_BACKUPS:-N}
if [[ "$REMOVE_BACKUPS" =~ ^[Yy]$ ]]; then
    echo -e "${RED}[4/7]${NC} Removing backups..."
    rm -rf ./backups
    echo "  Removed ./backups/"
else
    echo -e "${GREEN}[4/7]${NC} Keeping backups in ./backups/"
fi

# 5. Remove cron job
echo -e "${RED}[5/7]${NC} Removing backup cron job..."
if crontab -l 2>/dev/null | grep -q "minecraft-backup"; then
    crontab -l 2>/dev/null | grep -v "minecraft-backup" | crontab - 2>/dev/null || true
    echo "  Cron job removed."
else
    echo "  No cron job found."
fi

# 6. Remove firewall rule
echo -e "${RED}[6/7]${NC} Removing firewall rule for port 25565..."
sudo ufw delete allow 25565/tcp 2>/dev/null || true
echo "  Done."

# 7. Optionally remove Docker
echo ""
read -rp "Also uninstall Docker completely? [y/N]: " REMOVE_DOCKER
REMOVE_DOCKER=${REMOVE_DOCKER:-N}
if [[ "$REMOVE_DOCKER" =~ ^[Yy]$ ]]; then
    echo -e "${RED}[7/7]${NC} Uninstalling Docker..."
    sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    sudo rm -rf /var/lib/docker /var/lib/containerd
    sudo apt autoremove -y
    echo "  Docker removed."
else
    echo -e "${GREEN}[7/7]${NC} Keeping Docker installed."
    # Clean up dangling images/volumes
    echo "  Pruning unused Docker resources..."
    docker system prune -f 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Uninstall complete.${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "The following files remain (your config/scripts):"
echo "  - docker-compose.yml"
echo "  - Makefile"
echo "  - setup.sh, backup.sh, install-plugins.sh, uninstall.sh"
echo "  - plugins.txt"
if [[ ! "$REMOVE_BACKUPS" =~ ^[Yy]$ ]]; then
    echo "  - backups/"
fi
echo ""
echo "To remove these too: rm -rf $(pwd)"
echo ""
