#!/bin/bash
set -euo pipefail

PLUGINS_FILE="plugins.txt"
PLUGINS_DIR="./data/plugins"

mkdir -p "$PLUGINS_DIR"

if [ ! -f "$PLUGINS_FILE" ]; then
    echo "No plugins.txt found."
    exit 1
fi

echo "========================================="
echo "  Plugin Installer"
echo "========================================="
echo ""

INSTALLED=0
SKIPPED=0
FAILED=0

while IFS= read -r line; do
    # Skip empty lines and comments
    line=$(echo "$line" | xargs)
    [[ -z "$line" || "$line" == \#* ]] && continue

    echo "→ Processing: $line"

    if [[ "$line" == *.jar ]]; then
        # Direct JAR URL
        filename=$(basename "$line")
        if curl -fsSL -o "$PLUGINS_DIR/$filename" "$line"; then
            echo "  ✓ Downloaded $filename"
            ((INSTALLED++))
        else
            echo "  ✗ Failed to download $filename"
            ((FAILED++))
        fi

    elif [[ "$line" == *modrinth.com/plugin/* ]]; then
        # Modrinth plugin
        slug=$(echo "$line" | sed 's|.*/plugin/||' | sed 's|/.*||')
        echo "  Fetching from Modrinth: $slug"

        # Get the latest compatible version
        version_data=$(curl -fsSL "https://api.modrinth.com/v2/project/$slug/version?loaders=%5B%22paper%22,%22bukkit%22,%22spigot%22%5D&game_versions=%5B%22$(docker exec minecraft-server cat /data/version.txt 2>/dev/null || echo "1.21.4")%22%5D" 2>/dev/null || echo "[]")

        # Fallback: get latest version without game version filter
        if [ "$version_data" = "[]" ]; then
            version_data=$(curl -fsSL "https://api.modrinth.com/v2/project/$slug/version?loaders=%5B%22paper%22,%22bukkit%22,%22spigot%22%5D" 2>/dev/null || echo "[]")
        fi

        dl_url=$(echo "$version_data" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data:
        print(data[0]['files'][0]['url'])
except: pass
" 2>/dev/null || true)

        if [ -n "$dl_url" ]; then
            filename=$(basename "$dl_url" | sed 's|?.*||')
            if curl -fsSL -o "$PLUGINS_DIR/$filename" "$dl_url"; then
                echo "  ✓ Installed $filename"
                ((INSTALLED++))
            else
                echo "  ✗ Download failed for $slug"
                ((FAILED++))
            fi
        else
            echo "  ✗ Could not find compatible version for $slug"
            ((FAILED++))
        fi

    elif [[ "$line" == *github.com/* ]]; then
        # GitHub release
        repo=$(echo "$line" | sed 's|https://github.com/||' | sed 's|/$||')
        echo "  Fetching latest release from GitHub: $repo"

        dl_url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for asset in data.get('assets', []):
        if asset['name'].endswith('.jar'):
            print(asset['browser_download_url'])
            break
except: pass
" 2>/dev/null || true)

        if [ -n "$dl_url" ]; then
            filename=$(basename "$dl_url")
            if curl -fsSL -o "$PLUGINS_DIR/$filename" "$dl_url"; then
                echo "  ✓ Installed $filename"
                ((INSTALLED++))
            else
                echo "  ✗ Download failed for $repo"
                ((FAILED++))
            fi
        else
            echo "  ✗ No .jar found in latest release for $repo"
            ((FAILED++))
        fi

    elif [[ "$line" == *spigotmc.org/resources/* ]]; then
        # SpigotMC - extract resource ID
        resource_id=$(echo "$line" | grep -oP '\.\K[0-9]+' | tail -1)
        echo "  ⚠ SpigotMC ($resource_id) requires manual download due to Cloudflare protection."
        echo "    Download from: $line"
        echo "    Place .jar in: $PLUGINS_DIR/"
        ((SKIPPED++))

    else
        echo "  ⚠ Unknown source, skipping: $line"
        ((SKIPPED++))
    fi

    echo ""
done < "$PLUGINS_FILE"

echo "========================================="
echo "  Done: $INSTALLED installed, $SKIPPED skipped, $FAILED failed"
echo "========================================="
echo ""
echo "Restart the server to load new plugins: make restart"
