#!/bin/bash
# first-setup.sh - Otomatis membuat burner wallet dari seed phrase

WORKDIR="/workspaces/mawari-multi-wallet" # Sesuaikan jika nama repo berbeda
LOG_FILE="$WORKDIR/setup.log"
GENERATED_WALLETS_LOG="$WORKDIR/generated_wallets.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "╔════════════════════════════════════════════════╗"
echo "║   AUTO BURNER WALLET GENERATION & SETUP       ║"
echo "╚════════════════════════════════════════════════╝"
echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Deteksi codespace mana yang sedang berjalan
if [[ "$CODESPACE_NAME" == *"-1"* ]]; then
    OWNER_SECRET="$OWNERS_CS1"
    DERIVATION_OFFSET=0
    echo "🔍 Terdeteksi sebagai Codespace 1. Menggunakan OWNERS_CS1."
elif [[ "$CODESPACE_NAME" == *"-2"* ]]; then
    OWNER_SECRET="$OWNERS_CS2"
    DERIVATION_OFFSET=6
    echo "🔍 Terdeteksi sebagai Codespace 2. Menggunakan OWNERS_CS2."
else
    echo "❌ ERROR: Tidak dapat menentukan grup owner (CS1 atau CS2) dari nama Codespace."
    exit 1
fi

if [ -z "$OWNER_SECRET" ] || [ -z "$SEED_PHRASE" ]; then
    echo "❌ ERROR: Secret yang diperlukan tidak ditemukan!"
    exit 1
fi

echo "✅ Secret yang diperlukan ditemukan."
echo "Generated Burner Wallets:" > "$GENERATED_WALLETS_LOG"
echo "--------------------------" >> "$GENERATED_WALLETS_LOG"

IFS=',' read -r -a owners <<< "$OWNER_SECRET"

total_wallets=${#owners[@]}
echo "✅ Terdeteksi ${total_wallets} owner address. Akan membuat ${total_wallets} burner wallet."

for i in $(seq 0 $(($total_wallets - 1))); do
    wallet_index=$(($i + 1 + $DERIVATION_OFFSET))
    derivation_path_index=$(($i + $DERIVATION_OFFSET))
    wallet_dir=~/mawari/wallet_${wallet_index}
    config_file=${wallet_dir}/flohive-cache.json
    owner_address=${owners[$i]}

    echo "🔧 Memproses Owner #${wallet_index}: ${owner_address}"
    mkdir -p "$wallet_dir"

    wallet_json=$(node <<EOF
const ethers = require('ethers');
const wallet = ethers.Wallet.fromMnemonic("$SEED_PHRASE", "m/44'/60'/0'/0/${derivation_path_index}");
console.log(JSON.stringify({
  address: wallet.address,
  privateKey: wallet.privateKey
}));
EOF
)
    burner_address=$(echo "$wallet_json" | jq -r .address)
    burner_private_key=$(echo "$wallet_json" | jq -r .privateKey)

    echo "   -> Menghasilkan Burner Address: ${burner_address}"

    cat > "$config_file" <<EOF
{
  "burnerWallet": {
    "privateKey": "${burner_private_key}",
    "address": "${burner_address}"
  }
}
EOF
    chmod 600 "$config_file"
    echo "   ✅ File konfigurasi dibuat."

    echo "Owner #${wallet_index} (${owner_address}):" >> "$GENERATED_WALLETS_LOG"
    echo "  Burner Address: ${burner_address}" >> "$GENERATED_WALLETS_LOG"
    echo "" >> "$GENERATED_WALLETS_LOG"
done

echo ""
echo "✅ Setup selesai. Detail burner wallet tersimpan di ${GENERATED_WALLETS_LOG}"
touch /tmp/first_setup_done
