# Mawari Multi-Wallet Node Blueprint

Versi lanjutan yang dirancang untuk menjalankan beberapa Mawari Guardian Node di dalam satu GitHub Codespace (4-core) untuk efisiensi maksimal.

---

## 📋 Requirements

### Repository Secrets (GitHub Codespaces)
Di repositori ini, atur **2 secret** berikut.

**PENTING**: Jumlah *owner address* akan menentukan berapa banyak *burner wallet* yang akan dibuat secara otomatis.

| Secret Name | Description | Example (untuk 6 wallet) |
|---|---|---|
| `MAWARI_OWNER_ADDRESS_MULTI` | Daftar alamat Ethereum pemilik node, dipisahkan **koma (,)** tanpa spasi. | `0xOwner1...,0xOwner2...,0xOwner3...,0xOwner4...,0xOwner5...,0xOwner6...` |
| `MAWARI_SEED_PHRASE` | Satu **frasa sandi (seed phrase) 12 atau 24 kata** dari dompet baru yang Anda buat khusus untuk ini. | `word1 word2 word3 ... word12` |
