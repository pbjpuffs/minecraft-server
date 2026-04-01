#!/bin/bash
set -euo pipefail

# Minecraft server management helper

case "${1:-help}" in
    start)
        echo "Starting Minecraft server..."
        docker compose up -d
        echo "Server starting. Use './manage.sh logs' to watch progress."
        ;;
    stop)
        echo "Stopping Minecraft server..."
        docker compose down
        echo "Server stopped."
        ;;
    restart)
        echo "Restarting Minecraft server..."
        docker compose restart
        echo "Server restarted."
        ;;
    logs)
        docker compose logs -f
        ;;
    status)
        docker compose ps
        ;;
    console)
        echo "Entering RCON console (type 'quit' to exit)..."
        docker exec -i minecraft-server rcon-cli
        ;;
    backup)
        bash ./backup.sh
        ;;
    whitelist-add)
        if [ -z "${2:-}" ]; then
            echo "Usage: ./manage.sh whitelist-add <player_name>"
            exit 1
        fi
        docker exec minecraft-server rcon-cli "whitelist add $2"
        echo "Added $2 to whitelist."
        ;;
    whitelist-remove)
        if [ -z "${2:-}" ]; then
            echo "Usage: ./manage.sh whitelist-remove <player_name>"
            exit 1
        fi
        docker exec minecraft-server rcon-cli "whitelist remove $2"
        echo "Removed $2 from whitelist."
        ;;
    op)
        if [ -z "${2:-}" ]; then
            echo "Usage: ./manage.sh op <player_name>"
            exit 1
        fi
        docker exec minecraft-server rcon-cli "op $2"
        echo "Made $2 an operator."
        ;;
    players)
        docker exec minecraft-server rcon-cli "list"
        ;;
    help|*)
        echo "Minecraft Server Manager"
        echo ""
        echo "Usage: ./manage.sh <command>"
        echo ""
        echo "Commands:"
        echo "  start              Start the server"
        echo "  stop               Stop the server"
        echo "  restart            Restart the server"
        echo "  logs               Follow server logs"
        echo "  status             Show container status"
        echo "  console            Open RCON console"
        echo "  backup             Run a backup"
        echo "  whitelist-add      Add player to whitelist"
        echo "  whitelist-remove   Remove player from whitelist"
        echo "  op <player>        Make a player operator"
        echo "  players            List online players"
        echo ""
        ;;
esac
