# Mawari Multi-Wallet Node Blueprint

Versi lanjutan untuk menjalankan beberapa Mawari Guardian Node di satu GitHub Codespace (4-core).

## Requirements

### Repository Secrets (GitHub Codespaces)
Pastikan 3 secret ini diatur.

| Secret Name | Description | Example |
|---|---|---|
| `OWNERS_CS1` | Daftar 6 owner address pertama, dipisahkan koma. | `0xOwner1...,0xOwner2...` |
| `OWNERS_CS2` | Daftar 6 owner address berikutnya, dipisahkan koma. | `0xOwner7...,0xOwner8...` |
| `SEED_PHRASE` | Satu frasa sandi (seed phrase) 12 atau 24 kata. | `word1 word2 ... word12` |
