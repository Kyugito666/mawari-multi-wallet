#!/bin/bash
# auto-start.sh - Untuk Mawari Multi-Wallet

WORKDIR="/workspaces/mawari-multi-wallet"
LOG_FILE="$WORKDIR/autostart.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "╔════════════════════════════════════════════════╗"
echo "║      MAWARI MULTI-WALLET AUTO START           ║"
echo "╚════════════════════════════════════════════════╝"
echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"

# Tunggu first-setup selesai
MAX_WAIT=300
ELAPSED=0
while [ ! -f /tmp/first_setup_done ] && [ $ELAPSED -lt $MAX_WAIT ]; do
    echo "⏳ Waiting for first-setup.sh to complete... (${ELAPSED}s/${MAX_WAIT}s)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

if [ ! -f /tmp/first_setup_done ]; then
    echo "⚠️ WARNING: first-setup.sh may not have completed, but continuing..."
fi

# Deteksi codespace mana yang sedang berjalan
if [[ "$CODESPACE_NAME" == *"-1"* ]] || [[ "$CODESPACE_NAME" == *"node-1"* ]]; then
    OWNER_SECRET_CHECK="$OWNERS_CS1"
    echo "🔍 Terdeteksi sebagai Codespace 1."
elif [[ "$CODESPACE_NAME" == *"-2"* ]] || [[ "$CODESPACE_NAME" == *"node-2"* ]]; then
    OWNER_SECRET_CHECK="$OWNERS_CS2"
    echo "🔍 Terdeteksi sebagai Codespace 2."
else
    echo "⚠️ WARNING: Tidak dapat menentukan grup dari nama Codespace."
    echo "   CODESPACE_NAME: $CODESPACE_NAME"
    echo "   Mencoba menggunakan OWNERS_CS1 sebagai default..."
    OWNER_SECRET_CHECK="$OWNERS_CS1"
fi

if [ -z "$OWNER_SECRET_CHECK" ]; then
    echo "❌ ERROR: Secret owner tidak ditemukan!"
    echo "   Pastikan OWNERS_CS1 atau OWNERS_CS2 sudah diset di Codespace Secrets"
    exit 1
fi

# Cek apakah folder wallet ada
wallet_dirs=$(find ~/mawari -mindepth 1 -maxdepth 1 -type d -name "wallet_*" 2>/dev/null)
if [ -z "$wallet_dirs" ]; then
    echo "❌ ERROR: Tidak ada folder wallet yang ditemukan di ~/mawari/"
    echo "   Kemungkinan first-setup.sh gagal dijalankan."
    exit 1
fi

# Gabungkan semua owner untuk allowlist
ALL_OWNERS="$OWNERS_CS1,$OWNERS_CS2"
echo "✅ Menggunakan semua owner address untuk allowlist."

# Pull image Docker
export MNTESTNET_IMAGE=us-east4-docker.pkg.dev/mawarinetwork-dev/mwr-net-d-car-uses4-public-docker-registry-e62e/mawari-node:latest

echo "🐋 Pulling latest Mawari Docker image..."
if ! docker pull $MNTESTNET_IMAGE; then
    echo "⚠️ WARNING: Gagal pull image, mencoba menggunakan image yang sudah ada..."
fi

# Start semua node
started_count=0
for dir in $wallet_dirs; do
    wallet_index=$(basename "$dir" | sed 's/wallet_//')
    container_name="mawari-node-${wallet_index}"

    echo "🔄 Memeriksa Node #${wallet_index}..."

    # Cek apakah container sudah running
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "   ℹ️  Container ${container_name} sudah berjalan."
        started_count=$((started_count + 1))
    else
        echo "   🚀 Memulai container ${container_name}..."
        
        # Hapus container lama jika ada
        docker rm -f "$container_name" 2>/dev/null || true
        
        # Start container baru
        if docker run -d \
            --name "$container_name" \
            --restart unless-stopped \
            -v "${dir}:/app/cache" \
            -e OWNERS_ALLOWLIST="$ALL_OWNERS" \
            $MNTESTNET_IMAGE; then
            
            echo "   ✅ Container ${container_name} berhasil dimulai."
            started_count=$((started_count + 1))
        else
            echo "   ❌ ERROR: Gagal memulai container ${container_name}"
        fi
        
        sleep 2
    fi
done

echo ""
echo "════════════════════════════════════════════════"
echo "✅ Auto-start selesai! ${started_count} node aktif."
echo "════════════════════════════════════════════════"
echo ""
echo "📊 Status containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep mawari-node || echo "Tidak ada container mawari yang berjalan"

touch /tmp/auto_start_done
echo "🎉 Auto-start process completed at $(date '+%Y-%m-%d %H:%M:%S')"
