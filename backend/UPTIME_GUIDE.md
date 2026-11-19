# Panduan Mengatasi Cold Start Render (Free Tier)

Secara default, Render Free Tier akan "tertidur" (*spin down*) jika tidak ada request masuk selama 15 menit. Request pertama setelah tidur membutuhkan waktu ~30-50 detik untuk *spin up* (cold start).

Agar backend Tripy selalu **cepat dan responsif kapan saja** (< 3 detik), server Render perlu diping secara otomatis setiap 5-10 menit.

---

## Cara Setting Ping Gratis (Paling Mudah: UptimeRobot)

1. Buka [https://uptimerobot.com](https://uptimerobot.com) dan buat akun gratis (bisa Sign In dengan Google).
2. Klik tombol **"+ Add New Monitor"**.
3. Isi data berikut:
   - **Monitor Type:** `HTTP(s)`
   - **Friendly Name:** `TRIPIN Backend Health`
   - **URL (or IP):** `https://tripin-backend.onrender.com/health`
   - **Monitoring Interval:** `5 minutes`
4. Klik **"Create Monitor"**.

### Selesai! 🎉
UptimeRobot akan otomatis memanggil endpoint `/health` setiap 5 menit. Backend Render tidak akan pernah tidur, dan respon Tripy di aplikasi Android TRIPIN akan selalu instan!
