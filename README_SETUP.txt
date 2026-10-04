VANZ RANDOM GITHUB UPLOADER
===========================

SETUP:
1. Upload semua file/folder ini ke repository GitHub.
2. Edit netlify/functions/config.mjs:

   export const TARGET_REPO = "USERNAME/NAMA_REPO";

   TARGET_BRANCH biasanya "main".
   TARGET_FOLDER biasanya "vanz".

3. Deploy repository tersebut ke Netlify.
4. Netlify Functions directory: netlify/functions
5. Tambahkan environment variables:
   GITHUB_CLIENT_ID
   GITHUB_CLIENT_SECRET
   SESSION_SECRET

PERILAKU UPLOAD:
- Setiap klik Conversion membuat file Lua BARU.
- Nama file dibuat otomatis secara acak, contoh:
  vanz/vanz_mgabc123_91f4a2c8d7e1.lua
- Server mengecek nama tersebut belum ada sebelum membuat file.
- File lama tidak ditimpa oleh upload baru.
- Raw URL file baru dikembalikan dan dipakai untuk membuat loadstring.

CATATAN:
GitHub tetap memiliki batas ukuran file dan rate limit. Untuk source Lua biasa, batas ini biasanya jauh dari masalah.
