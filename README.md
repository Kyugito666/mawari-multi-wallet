# Mawari Multi-Wallet Node Blueprint

Versi lanjutan yang dirancang untuk menjalankan 6 node Mawari Guardian di dalam satu GitHub Codespace (4-core), dan dapat di-deploy ganda oleh orkestrator untuk total 12 node.

---

## 📋 Requirements

### Repository Secrets (GitHub Codespaces)
Pastikan 3 secret ini diatur di pengaturan Codespaces repositori ini.

| Secret Name | Description | Example |
|---|---|---|
| `OWNERS_CS1` | Daftar 6 owner address pertama, dipisahkan koma. | `0xOwner1...,0xOwner2...` |
| `OWNERS_CS2` | Daftar 6 owner address berikutnya, dipisahkan koma. | `0xOwner7...,0xOwner8...` |
| `SEED_PHRASE` | Satu frasa sandi (seed phrase) 12 atau 24 kata. | `word1 word2 ... word12` |
