# Mawari Multi-Wallet Node Blueprint

Versi lanjutan untuk menjalankan beberapa Mawari Guardian Node di satu GitHub Codespace (4-core).

## Requirements

### Repository Secrets (GitHub Codespaces)
Pastikan 2 secret ini diatur (diotomatiskan oleh `setup-helper.ps1`).

| Secret Name | Description |
|---|---|
| `MAWARI_OWNER_ADDRESS_MULTI` | Daftar alamat Ethereum pemilik node, dipisahkan koma. |
| `MAWARI_SEED_PHRASE` | Satu frasa sandi (seed phrase) 12 atau 24 kata. |
