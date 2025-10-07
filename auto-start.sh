#!/bin/bash
# auto-start.sh - Untuk Mawari Multi-Wallet

WORKDIR="/workspaces/mawari-multi-wallet" # Sesuaikan jika perlu
LOG_FILE="$WORKDIR/autostart.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "╔════════════════════════════════════════════════╗"
echo "║      MAWARI MULTI-WALLET AUTO START           ║"
echo "╚════════════════════════════════════════════════╝"
echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"

# Deteksi codespace mana yang sedang berjalan
if [[ "$CODESPACE_NAME" == *"-1"* ]]; then
    OWNER_SECRET="$OWNERS_CS1"
    echo "🔍 Terdeteksi sebagai Codespace 1."
elif [[ "$CODESPACE_NAME" == *"-2"* ]]; then
    OWNER_SECRET="$OWNERS_CS2"
    echo "🔍 Terdeteksi sebagai Codespace 2."
else
    echo "❌ ERROR: Tidak dapat menentukan grup owner (CS1 atau CS2) dari nama Codespace."
    exit 1
fi

if [ -z "$OWNER_SECRET" ]; then
    echo "❌ ERROR: Secret owner yang sesuai tidak ditemukan!"
    exit 1
fi

wallet_dirs=$(find ~/mawari -mindepth 1 -maxdepth 1 -type d -name "wallet_*")
if [ -z "$wallet_dirs" ]; then
    echo "❌ ERROR: Tidak ada folder wallet yang ditemukan."
    exit 1
fi

IFS=',' read -r -a owners <<< "$OWNER_SECRET"
main_owner=${owners[0]}
echo "✅ Menggunakan Owner Address utama untuk allowlist: $main_owner"

export MNTESTNET_IMAGE=us-east4-docker.pkg.dev/mawarinetwork-dev/mwr-net-d-car-uses4-public-docker-registry-e62e/mawari-node:latest

for dir in $wallet_dirs; do
    wallet_index=$(basename "$dir" | sed 's/wallet_//')
    container_name="mawari-node-${wallet_index}"

    echo "🔄 Memeriksa Node #${wallet_index}..."

    if docker ps | grep -q "$container_name"; then
        echo "   ℹ️  Container ${container_name} sudah berjalan."
    else
        echo "   🚀 Memulai container ${container_name}..."
        docker rm -f "$container_name" 2>/dev/null || true
        
        docker run -d \
            --name "$container_name" \
            --pull always \
            -v "${dir}:/app/cache" \
            -e OWNERS_ALLOWLIST="$main_owner" \
            $MNTESTNET_IMAGE
        
        echo "   ✅ Container ${container_name} dimulai."
        sleep 3
    fi
done

echo ""
echo "✅ Proses auto-start selesai. Cek status dengan 'docker ps'"
touch /tmp/auto_start_done
