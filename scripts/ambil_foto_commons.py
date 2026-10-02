#!/usr/bin/env python3
"""Mengambil foto destinasi asli dari Wikimedia Commons untuk TRIPIN.

Dua tahap (sengaja dipisah supaya foto dipilih manusia/asisten setelah dilihat):

  1) cari   : cari kandidat per destinasi, simpan thumbnail + lembar kontak (contact sheet)
              ke folder kerja, dan metadata kandidat ke kandidat.json.
              python3 scripts/ambil_foto_commons.py cari --kerja /tmp/foto [--id d05]

  2) unduh  : unduh foto terpilih (scripts/foto_pilihan.json), kompres ke JPEG, simpan ke
              assets/destinasi/<id>/N.jpg dan tulis assets/destinasi/kredit.json.
              python3 scripts/ambil_foto_commons.py unduh --kerja /tmp/foto

Hanya lisensi CC0 / domain publik / CC BY / CC BY-SA yang dipakai (tanpa NC/ND).
Wajib mencantumkan kredit (kredit.json ditampilkan di app).
"""
import argparse
import concurrent.futures as cf
import html
import io
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

API = "https://commons.wikimedia.org/w/api.php"
UA = "TRIPIN-student-app/1.0 (arielafriza88@gmail.com)"
ROOT = Path(__file__).resolve().parent.parent
PILIHAN = ROOT / "scripts" / "foto_pilihan.json"
OUT_ASSET = ROOT / "assets" / "destinasi"

# id -> daftar kueri pencarian (berurutan; hasil digabung tanpa duplikat).
KUERI = {
    "d01": ["Danau Toba", "Lake Toba", "Danau Toba Samosir panorama"],
    "d02": ["Bukit Lawang", "Bukit Lawang orangutan", "Bukit Lawang Bohorok river"],
    "d03": ["Berastagi", "Brastagi Karo", "Pasar Buah Berastagi"],
    "d04": ["Taman Cadika Medan", "Cadika Pramuka Medan"],
    "d05": ["Istana Maimun", "Maimun Palace Medan"],
    "d06": ["Air Terjun Sipiso-piso", "Sipiso-piso waterfall"],
    "d07": ["Tangkahan", "Tangkahan elephant Gunung Leuser"],
    "d08": ["Tomok Samosir", "Makam Raja Sidabutar Tomok", "Tomok Pulau Samosir"],
    "d09": ["Museum Negeri Sumatera Utara", "Museum Negeri Sumatera Utara Medan"],
    "d10": ["Sidamanik tea plantation", "Kebun Teh Sidamanik", "Kebun teh Simalungun"],
    "d11": ["Danau Lau Kawar", "Lau Kawar Sinabung"],
    "d12": ["Pantai Cermin Serdang Bedagai", "Pantai Cermin"],
    "d13": ["Bukit Gundaling", "Gundaling Berastagi"],
    "d14": ["Air Terjun Dua Warna", "Dua Warna waterfall Karo"],
    "d15": ["Taman Simalem Resort", "Simalem Resort Karo"],
    "d16": ["Mangrove Percut Sei Tuan", "Hutan mangrove Medan", "Mangrove Deli Serdang"],
    "d17": ["Pantai Sri Mersing", "Sri Mersing Serdang Bedagai"],
    "d18": ["Rumah Bolon Simalungun", "Rumah Bolon Pematang Purba", "Istana Pematang Purba"],
    "d19": ["Pelabuhan Belawan", "Belawan Medan fish market", "Pasar Ikan Belawan"],
    "d20": ["Kopi Sidikalang", "Sidikalang Dairi coffee", "Sidikalang"],
    "banner": ["Danau Toba panorama", "Lake Toba Samosir view", "Sumatera Utara landscape"],
    "d21": ["Tjong A Fie Mansion", "Rumah Tjong A Fie Medan"],
    "d22": ["Masjid Raya Al Mashun", "Masjid Raya Medan"],
    "d23": ["Rahmat International Wildlife Museum", "Rahmat Gallery Medan"],
    "d24": ["Merdeka Walk Medan", "Lapangan Merdeka Medan"],
    "d25": ["Taman Alam Lumbini", "Lumbini Berastagi pagoda"],
    "d26": ["Gunung Sibayak", "Sibayak crater"],
    "d27": ["Bukit Holbung", "Holbung Samosir"],
    "d28": ["Pantai Parbaba", "Parbaba Samosir"],
    "d29": ["Air Terjun Efrata", "Efrata waterfall Samosir"],
    "d30": ["Pantai Sorake", "Sorake Beach Nias", "Lagundri Bay surf"],
    "d31": ["Tao Silalahi", "Silalahi Danau Toba"],
    "d32": ["Pusuk Buhit", "Pusuk Buhit Samosir"],
}

LISENSI_OK = re.compile(r"^(CC0|Public domain|PD|CC BY(-SA)? \d\.\d|CC BY(-SA)?( \d\.\d)?)", re.I)
LISENSI_NO = re.compile(r"NC|ND", re.I)
NAMA_BURUK = re.compile(r"(map|peta|logo|flag|lambang|coat|diagram|icon|stamp|poster|brosur|\.svg|\.pdf|\.tif)", re.I)


def get(url, params=None, tries=4):
    if params:
        url += "?" + urllib.parse.urlencode(params)
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=40) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001
            if i == tries - 1:
                raise
            time.sleep(2 + 3 * i)
            print("  ulang:", e, file=sys.stderr)


def bersih(teks):
    return html.unescape(re.sub(r"<[^>]+>", "", teks or "")).strip()


def cari_kueri(q, batas=12):
    data = json.loads(get(API, {
        "action": "query", "generator": "search", "gsrsearch": q, "gsrnamespace": 6,
        "gsrlimit": batas, "prop": "imageinfo", "iiprop": "url|extmetadata|size|mime",
        "iiurlwidth": 1000, "format": "json",
    }))
    hasil = []
    for p in data.get("query", {}).get("pages", {}).values():
        ii = (p.get("imageinfo") or [{}])[0]
        m = ii.get("extmetadata", {})
        lis = bersih(m.get("LicenseShortName", {}).get("value", ""))
        judul = p["title"]
        if ii.get("mime") not in ("image/jpeg", "image/png"):
            continue
        if NAMA_BURUK.search(judul):
            continue
        if not lis or LISENSI_NO.search(lis) or not LISENSI_OK.match(lis):
            continue
        if ii.get("width", 0) < 1000 or ii.get("height", 0) < 600:
            continue
        hasil.append({
            "judul": judul,
            "lebar": ii["width"], "tinggi": ii["height"],
            "lisensi": lis,
            "lisensi_url": bersih(m.get("LicenseUrl", {}).get("value", "")),
            "fotografer": bersih(m.get("Artist", {}).get("value", "")) or "Tidak diketahui",
            "halaman": ii.get("descriptionshorturl") or ii.get("descriptionurl"),
            "thumb": ii.get("thumburl"),
            "url": ii.get("url"),
        })
    return hasil


def cmd_cari(a):
    kerja = Path(a.kerja)
    kerja.mkdir(parents=True, exist_ok=True)
    semua = {}
    ids = [a.id] if a.id else list(KUERI)
    for did in ids:
        print("==", did)
        gabung, lihat = [], set()
        for q in KUERI[did]:
            for c in cari_kueri(q):
                if c["judul"] not in lihat:
                    lihat.add(c["judul"])
                    gabung.append(c)
            time.sleep(0.6)
        gabung = gabung[:16]
        semua[did] = gabung
        # lembar kontak bernomor
        sel, kolom = 260, 4
        baris = (len(gabung) + kolom - 1) // kolom or 1
        sheet = Image.new("RGB", (kolom * sel, baris * (sel + 22)), "white")
        d = ImageDraw.Draw(sheet)
        for i, c in enumerate(gabung):
            try:
                img = Image.open(io.BytesIO(get(c["thumb"]))).convert("RGB")
                img = ImageOps.fit(img, (sel - 6, sel - 6))
                x, y = (i % kolom) * sel, (i // kolom) * (sel + 22)
                sheet.paste(img, (x + 3, y + 3))
                d.text((x + 6, y + sel - 2), f"{i}  {c['judul'][5:40]}", fill="black")
            except Exception as e:  # noqa: BLE001
                print("  gagal thumb", c["judul"], e, file=sys.stderr)
            time.sleep(0.4)
        sheet.save(kerja / f"{did}.jpg", quality=80)
        print("  kandidat:", len(gabung))
    prev = {}
    f = kerja / "kandidat.json"
    if f.exists():
        prev = json.loads(f.read_text())
    prev.update(semua)
    f.write_text(json.dumps(prev, ensure_ascii=False, indent=1))


def _kandidat_id(did, per_id=6):
    gabung, lihat = [], set()
    for q in KUERI[did]:
        try:
            for c in cari_kueri(q):
                if c["judul"] not in lihat:
                    lihat.add(c["judul"])
                    gabung.append(c)
        except Exception as e:  # noqa: BLE001
            print("  gagal cari", did, q, e, file=sys.stderr)
    # utamakan foto lanskap (lebar >= tinggi) dan resolusi cukup
    gabung.sort(key=lambda c: (c["lebar"] < c["tinggi"], -min(c["lebar"], 4000)))
    return did, gabung[:per_id]


def cmd_cepat(a):
    """Cari semua destinasi paralel, lalu buat 3 lembar kontak (7 baris x 3 kandidat)."""
    kerja = Path(a.kerja)
    kerja.mkdir(parents=True, exist_ok=True)
    semua = {}
    pilih = [i for i in (a.ids or "").split(",") if i] or list(KUERI)
    with cf.ThreadPoolExecutor(max_workers=4) as ex:
        for did, c in ex.map(_kandidat_id, pilih):
            semua[did] = c
            print(did, len(c))
    kf = kerja / "kandidat.json"
    lama = json.loads(kf.read_text()) if kf.exists() else {}
    lama.update(semua)
    kf.write_text(json.dumps(lama, ensure_ascii=False, indent=1))

    def thumb(args):
        did, i, c = args
        try:
            img = Image.open(io.BytesIO(get(c["thumb"]))).convert("RGB")
            return did, i, ImageOps.fit(img, (230, 160))
        except Exception as e:  # noqa: BLE001
            print("  gagal thumb", did, i, e, file=sys.stderr)
            return did, i, None

    tugas = [(d, i, c) for d, cs in semua.items() for i, c in enumerate(cs[:3])]
    gambar = {}
    with cf.ThreadPoolExecutor(max_workers=4) as ex:
        for did, i, img in ex.map(thumb, tugas):
            gambar[(did, i)] = img
    ids = pilih
    for n in range(0, len(ids), 7):
        grup = ids[n:n + 7]
        sheet = Image.new("RGB", (3 * 236 + 70, len(grup) * 176), "white")
        d = ImageDraw.Draw(sheet)
        for r, did in enumerate(grup):
            d.text((4, r * 176 + 70), did, fill="black")
            for i in range(3):
                img = gambar.get((did, i))
                if img:
                    sheet.paste(img, (70 + i * 236, r * 176 + 2))
                    d.text((72 + i * 236, r * 176 + 162), f"{i}: {semua[did][i]['judul'][5:34]}", fill="black")
        sheet.save(kerja / f"lembar_{n // 7 + 1}.jpg", quality=82)
    print("selesai")


def cmd_unduh(a):
    """Unduh foto terpilih. foto_pilihan.json: {id: [sumber, indeks, (kunci)]} dengan sumber
    kandidat/tambahan/geo = berkas JSON di folder kerja. d16 dan d17 sengaja tidak punya foto."""
    kerja = Path(a.kerja)
    sumber = {n: json.loads((kerja / f"{n}.json").read_text()) for n in ("kandidat", "tambahan", "geo")}
    pilihan = json.loads(PILIHAN.read_text())
    OUT_ASSET.mkdir(parents=True, exist_ok=True)
    kredit_f = OUT_ASSET / "kredit.json"
    kredit = json.loads(kredit_f.read_text()) if kredit_f.exists() else {}
    for did, rujuk in pilihan.items():
        if a.id and did != a.id:
            continue
        nama, idx = rujuk[0], rujuk[1]
        kunci = rujuk[2] if len(rujuk) > 2 else did
        c = sumber[nama][kunci][idx]
        tujuan = OUT_ASSET / did
        tujuan.mkdir(parents=True, exist_ok=True)
        img = Image.open(io.BytesIO(get(c["thumb"]))).convert("RGB")
        img.thumbnail((1000, 1000))
        path = tujuan / "1.jpg"
        img.save(path, quality=76, optimize=True, progressive=True)
        kredit[did] = [{
            "file": f"assets/destinasi/{did}/1.jpg",
            "judul": c["judul"].removeprefix("File:"),
            "fotografer": c["fotografer"],
            "lisensi": c["lisensi"],
            "lisensiUrl": c["lisensi_url"],
            "sumber": c["halaman"],
        }]
        print(did, path.stat().st_size // 1024, "KB", c["judul"])
        time.sleep(0.3)
    kredit_f.write_text(json.dumps(kredit, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    c1 = sp.add_parser("cari")
    c1.add_argument("--kerja", required=True)
    c1.add_argument("--id")
    c3 = sp.add_parser("cepat")
    c3.add_argument("--kerja", required=True)
    c3.add_argument("--ids", help="daftar id dipisah koma (default: semua)")
    c2 = sp.add_parser("unduh")
    c2.add_argument("--kerja", required=True)
    c2.add_argument("--id")
    args = ap.parse_args()
    {"cari": cmd_cari, "cepat": cmd_cepat, "unduh": cmd_unduh}[args.cmd](args)
