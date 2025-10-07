#!/bin/bash
# first-setup.sh - Otomatis membuat burner wallet dari seed phrase

set -e  # Exit on error

WORKDIR="/workspaces/mawari-multi-wallet"
LOG_FILE="$WORKDIR/setup.log"
GENERATED_WALLETS_LOG="$WORKDIR/generated_wallets.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "╔════════════════════════════════════════════════╗"
echo "║   AUTO BURNER WALLET GENERATION & SETUP       ║"
echo "╚════════════════════════════════════════════════╝"
echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"

# Load NVM jika perlu
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Verifikasi Node.js tersedia
if ! command -v node &> /dev/null; then
    echo "❌ ERROR: Node.js tidak ditemukan!"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✅ Node.js version: $NODE_VERSION"

# Verifikasi ethers package
if ! node -e "require('ethers')" 2>/dev/null; then
    echo "⚠️ ethers package tidak ditemukan, mencoba install..."
    npm install -g ethers
fi

# Deteksi codespace
if [[ "$CODESPACE_NAME" == *"-1"* ]] || [[ "$CODESPACE_NAME" == *"node-1"* ]]; then
    OWNER_SECRET="$OWNERS_CS1"
    DERIVATION_OFFSET=0
    echo "🔍 Terdeteksi sebagai Codespace 1. Menggunakan OWNERS_CS1."
elif [[ "$CODESPACE_NAME" == *"-2"* ]] || [[ "$CODESPACE_NAME" == *"node-2"* ]]; then
    OWNER_SECRET="$OWNERS_CS2"
    DERIVATION_OFFSET=6
    echo "🔍 Terdeteksi sebagai Codespace 2. Menggunakan OWNERS_CS2."
else
    echo "⚠️ WARNING: Tidak dapat menentukan grup dari CODESPACE_NAME: $CODESPACE_NAME"
    echo "   Menggunakan OWNERS_CS1 sebagai default (offset=0)"
    OWNER_SECRET="$OWNERS_CS1"
    DERIVATION_OFFSET=0
fi

# Validasi secrets
if [ -z "$OWNER_SECRET" ]; then
    echo "❌ ERROR: Owner secret (OWNERS_CS1/CS2) tidak ditemukan!"
    echo "   Pastikan secret sudah diset di repository Codespace settings"
    exit 1
fi

if [ -z "$SEED_PHRASE" ]; then
    echo "❌ ERROR: SEED_PHRASE tidak ditemukan!"
    echo "   Pastikan secret SEED_PHRASE sudah diset"
    exit 1
fi

echo "✅ Semua secret yang diperlukan ditemukan."

# Buat direktori mawari
mkdir -p ~/mawari

# Siapkan log
echo "Generated Burner Wallets" > "$GENERATED_WALLETS_LOG"
echo "========================" >> "$GENERATED_WALLETS_LOG"
echo "Timestamp: $(date)" >> "$GENERATED_WALLETS_LOG"
echo "" >> "$GENERATED_WALLETS_LOG"

# Parse owner addresses
IFS=',' read -r -a owners <<< "$OWNER_SECRET"

total_wallets=${#owners[@]}
echo "✅ Terdeteksi ${total_wallets} owner address."
echo "   Derivation offset: $DERIVATION_OFFSET"
echo ""

# Generate wallets
success_count=0
for i in $(seq 0 $(($total_wallets - 1))); do
    wallet_index=$(($i + 1 + $DERIVATION_OFFSET))
    derivation_path_index=$(($i + $DERIVATION_OFFSET))
    wallet_dir=~/mawari/wallet_${wallet_index}
    config_file=${wallet_dir}/flohive-cache.json
    owner_address=${owners[$i]}

    echo "🔧 Processing Wallet #${wallet_index}..."
    echo "   Owner: ${owner_address}"
    echo "   Derivation: m/44'/60'/0'/0/${derivation_path_index}"
    
    mkdir -p "$wallet_dir"

    # Generate wallet menggunakan Node.js
    wallet_json=$(node -e "
        const ethers = require('ethers');
        try {
            const wallet = ethers.Wallet.fromMnemonic('${SEED_PHRASE}', \"m/44'/60'/0'/0/${derivation_path_index}\");
            console.log(JSON.stringify({
                address: wallet.address,
                privateKey: wallet.privateKey
            }));
        } catch(e) {
            console.error('ERROR:', e.message);
            process.exit(1);
        }
    " 2>&1)
    
    if [ $? -ne 0 ]; then
        echo "   ❌ ERROR generating wallet: $wallet_json"
        continue
    fi

    burner_address=$(echo "$wallet_json" | jq -r .address)
    burner_private_key=$(echo "$wallet_json" | jq -r .privateKey)

    if [ -z "$burner_address" ] || [ "$burner_address" == "null" ]; then
        echo "   ❌ ERROR: Failed to generate burner address"
        continue
    fi

    echo "   → Burner Address: ${burner_address}"

    # Buat config file
    cat > "$config_file" <<EOF
{
  "burnerWallet": {
    "privateKey": "${burner_private_key}",
    "address": "${burner_address}"
  }
}
EOF
    
    chmod 600 "$config_file"
    echo "   ✅ Config file created"
    
    success_count=$((success_count + 1))

    # Log ke file
    echo "Wallet #${wallet_index}:" >> "$GENERATED_WALLETS_LOG"
    echo "  Owner Address: ${owner_address}" >> "$GENERATED_WALLETS_LOG"
    echo "  Burner Address: ${burner_address}" >> "$GENERATED_WALLETS_LOG"
    echo "  Config: ${config_file}" >> "$GENERATED_WALLETS_LOG"
    echo "" >> "$GENERATED_WALLETS_LOG"
    
    echo ""
done

echo "════════════════════════════════════════════════"
echo "✅ Setup Complete!"
echo "   Total wallets created: ${success_count}/${total_wallets}"
echo "   Details saved to: ${GENERATED_WALLETS_LOG}"
echo "════════════════════════════════════════════════"

# Verifikasi hasil
wallet_count=$(find ~/mawari -mindepth 1 -maxdepth 1 -type d -name "wallet_*" | wc -l)
echo "📁 Wallet directories created: ${wallet_count}"

if [ $wallet_count -eq 0 ]; then
    echo "❌ ERROR: No wallet directories were created!"
    exit 1
fi

touch /tmp/first_setup_done
echo "🎉 First setup completed successfully at $(date '+%Y-%m-%d %H:%M:%S')"
