#!/usr/bin/env bash
# Menjalankan app di HP Android (kabel USB) atau emulator dengan chatbot tersambung.
# Pakai: ./scripts/run_android.sh [argumen flutter run lainnya]
# Prasyarat: backend jalan (cd backend && npm run dev), USB debugging aktif.
set -euo pipefail
cd "$(dirname "$0")/.."

ADB="${ADB:-$(command -v adb || echo "$HOME/Library/Android/sdk/platform-tools/adb")}"

if ! "$ADB" devices | awk 'NR>1 && $2=="device"' | grep -q .; then
  echo "Tidak ada perangkat Android terhubung. Colok HP (USB debugging aktif) atau jalankan emulator." >&2
  exit 1
fi

"$ADB" reverse tcp:3000 tcp:3000
if ! curl -fs -m 3 localhost:3000/health >/dev/null; then
  echo "Peringatan: backend belum menjawab di localhost:3000 (jalankan: cd backend && npm run dev)." >&2
fi

exec flutter run "$@"
