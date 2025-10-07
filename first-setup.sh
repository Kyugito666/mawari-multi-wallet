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

if [ -z "$MAWARI_OWNER_ADDRESS_MULTI" ] || [ -z "$MAWARI_SEED_PHRASE" ]; then
    echo "❌ ERROR: MAWARI_OWNER_ADDRESS_MULTI atau MAWARI_SEED_PHRASE tidak ditemukan!"
    exit 1
fi

echo "✅ Secret yang diperlukan ditemukan."
echo "Generated Burner Wallets:" > "$GENERATED_WALLETS_LOG"
echo "--------------------------" >> "$GENERATED_WALLETS_LOG"

IFS=',' read -r -a owners <<< "$MAWARI_OWNER_ADDRESS_MULTI"

total_wallets=${#owners[@]}
echo "✅ Terdeteksi ${total_wallets} owner address. Akan membuat ${total_wallets} burner wallet."

for i in $(seq 0 $(($total_wallets - 1))); do
    wallet_index=$(($i + 1))
    wallet_dir=~/mawari/wallet_${wallet_index}
    config_file=${wallet_dir}/flohive-cache.json
    owner_address=${owners[$i]}

    echo "🔧 Memproses Owner #${wallet_index}: ${owner_address}"
    mkdir -p "$wallet_dir"

    wallet_json=$(node <<EOF
const ethers = require('ethers');
const wallet = ethers.Wallet.fromMnemonic("$MAWARI_SEED_PHRASE", "m/44'/60'/0'/0/$i");
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

    echo "Owner #${wallet_index}: ${owner_address}" >> "$GENERATED_WALLETS_LOG"
    echo "  Burner Address: ${burner_address}" >> "$GENERATED_WALLETS_LOG"
    echo "" >> "$GENERATED_WALLETS_LOG"
done

echo ""
echo "✅ Setup selesai. Detail burner wallet tersimpan di ${GENERATED_WALLETS_LOG}"
touch /tmp/first_setup_done
