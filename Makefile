.PHONY: help setup start stop restart logs status console backup players op whitelist-add whitelist-remove update plugins plugins-list plugins-dir

# Default target
help:
	@echo ""
	@echo "  Minecraft Server Manager"
	@echo "  ========================"
	@echo ""
	@echo "  Setup:"
	@echo "    make setup              Install Docker, configure firewall, prepare everything"
	@echo ""
	@echo "  Server:"
	@echo "    make start              Start the server"
	@echo "    make stop               Stop the server"
	@echo "    make restart            Restart the server"
	@echo "    make update             Pull latest image and restart"
	@echo ""
	@echo "  Monitor:"
	@echo "    make logs               Follow server logs (Ctrl+C to exit)"
	@echo "    make status             Show if server is running"
	@echo "    make players            List online players"
	@echo ""
	@echo "  Admin:"
	@echo "    make console            Open server console (type 'quit' to exit)"
	@echo "    make op NAME=Steve      Make a player operator"
	@echo "    make whitelist-add NAME=Steve"
	@echo "    make whitelist-remove NAME=Steve"
	@echo ""
	@echo "  Plugins:"
	@echo "    make plugins            Install/update plugins from plugins.txt"
	@echo "    make plugins-list       Show installed plugin files"
	@echo "    make plugins-dir        Open plugins folder for manual installs"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make backup             Backup world data"
	@echo "    make setup-cron         Install automatic backups every 6 hours"
	@echo ""

# ── Setup ──────────────────────────────────────────────

setup:
	@chmod +x setup.sh backup.sh
	@bash setup.sh

# ── Server ─────────────────────────────────────────────

start:
	@echo "Starting Minecraft server..."
	@docker compose up -d
	@echo "Server starting. Run 'make logs' to watch progress."

stop:
	@echo "Stopping Minecraft server..."
	@docker compose down
	@echo "Server stopped."

restart:
	@echo "Restarting Minecraft server..."
	@docker compose restart
	@echo "Server restarted."

update:
	@echo "Pulling latest image and restarting..."
	@docker compose pull
	@docker compose up -d
	@echo "Updated and restarted."

# ── Monitor ────────────────────────────────────────────

logs:
	@docker compose logs -f

status:
	@docker compose ps

players:
	@docker exec minecraft-server rcon-cli "list"

# ── Admin ──────────────────────────────────────────────

console:
	@echo "Entering RCON console (type 'quit' to exit)..."
	@docker exec -it minecraft-server rcon-cli

op:
ifndef NAME
	@echo "Usage: make op NAME=PlayerName"
else
	@docker exec minecraft-server rcon-cli "op $(NAME)"
	@echo "$(NAME) is now an operator."
endif

whitelist-add:
ifndef NAME
	@echo "Usage: make whitelist-add NAME=PlayerName"
else
	@docker exec minecraft-server rcon-cli "whitelist add $(NAME)"
	@echo "$(NAME) added to whitelist."
endif

whitelist-remove:
ifndef NAME
	@echo "Usage: make whitelist-remove NAME=PlayerName"
else
	@docker exec minecraft-server rcon-cli "whitelist remove $(NAME)"
	@echo "$(NAME) removed from whitelist."
endif

# ── Plugins ────────────────────────────────────────────

plugins:
	@chmod +x install-plugins.sh
	@bash install-plugins.sh

plugins-list:
	@echo "Installed plugins:"
	@ls -lh data/plugins/*.jar 2>/dev/null || echo "  No plugins installed yet."

plugins-dir:
	@mkdir -p data/plugins
	@echo "Plugin directory: $(PWD)/data/plugins/"
	@echo "Drop .jar files there and run 'make restart'"

# ── Maintenance ────────────────────────────────────────

backup:
	@bash backup.sh

setup-cron:
	@(crontab -l 2>/dev/null; echo "0 */6 * * * cd $(PWD) && bash backup.sh >> /var/log/minecraft-backup.log 2>&1") | sort -u | crontab -
	@echo "Auto-backup installed: every 6 hours."
	@echo "Current crontab:"
	@crontab -l
