import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/models/user.dart';
import 'package:tugas_kelompok/providers/auth_provider.dart';
import 'package:tugas_kelompok/services/auth_repository.dart';
import 'package:tugas_kelompok/services/password_hasher.dart';

const _cepat = PasswordHasher(pakaiIsolate: false, iterasi: 4);

AuthProvider baru({DateTime Function()? sekarang, PasswordHasher hasher = _cepat}) =>
    AuthProvider(hasher: hasher, sekarang: sekarang);

Future<String> isiPrefsUsers() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('tripin_users') ?? '';
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PasswordHasher', () {
    test('format, verifikasi benar/salah, dan garam berbeda menghasilkan hash berbeda', () {
      final a = PasswordHasher.hashSinkron('rahasia1', iterasi: 4);
      final b = PasswordHasher.hashSinkron('rahasia1', iterasi: 4);
      expect(a, startsWith(r'pbkdf2$4$'));
      expect(a, isNot(b));
      expect(a.contains('rahasia1'), isFalse);
      expect(PasswordHasher.verifikasiSinkron('rahasia1', a), isTrue);
      expect(PasswordHasher.verifikasiSinkron('rahasia2', a), isFalse);
      expect(PasswordHasher.verifikasiSinkron('', a), isFalse);
    });

    test('vektor uji PBKDF2-HMAC-SHA256 (RFC 7914: "passwd"/"salt", 1 iterasi)', () {
      final h = PasswordHasher.hashSinkron('passwd', garam: utf8.encode('salt'), iterasi: 1);
      final hashB64 = h.split(r'$').last;
      final hex = base64Decode(hashB64).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc');
    });

    test('hash rusak atau format asing ditolak tanpa crash', () {
      for (final x in ['', 'abc', r'pbkdf2$x$y$z', r'pbkdf2$4$bukan-base64!$zz', r'md5$1$a$b']) {
        expect(PasswordHasher.verifikasiSinkron('apa saja', x), isFalse, reason: x);
      }
    });

    test('perluDiperbarui: iterasi lama atau format asing', () {
      const baru = PasswordHasher(iterasi: 100);
      expect(baru.perluDiperbarui(PasswordHasher.hashSinkron('x', iterasi: 10)), isTrue);
      expect(baru.perluDiperbarui(PasswordHasher.hashSinkron('x', iterasi: 100)), isFalse);
      expect(baru.perluDiperbarui('polos'), isTrue);
    });

    test('versi isolate memberi hasil yang sama dengan versi sinkron', () async {
      const h = PasswordHasher(iterasi: 50);
      final tersimpan = await h.hash('kata sandi');
      expect(await h.verifikasi('kata sandi', tersimpan), isTrue);
      expect(await h.verifikasi('salah', tersimpan), isFalse);
    });
  });

  group('AuthProvider', () {
    test('daftar lalu masuk; password polos tidak tersimpan di penyimpanan', () async {
      final a = baru();
      await a.muatData();
      expect(await a.register('Ari Test', 'Ari@Test.id', 'rahasia1'), isNull);
      expect(await a.login('ari@test.id', 'rahasia1'), isNull);
      expect(a.currentUser?.nama, 'Ari Test');

      final mentah = await isiPrefsUsers();
      expect(mentah.contains('rahasia1'), isFalse);
      expect(mentah, contains('pbkdf2'));
    });

    test('email dinormalisasi: duplikat beda huruf ditolak, login tidak peka huruf besar', () async {
      final a = baru();
      await a.muatData();
      await a.register('Ari', 'ari@test.id', 'rahasia1');
      expect(await a.register('Ari2', '  ARI@test.ID ', 'lain123'), 'Email sudah terdaftar');
      expect(await a.login('ARI@TEST.ID', 'rahasia1'), isNull);
    });

    test('password salah atau email tak dikenal memberi pesan yang sama', () async {
      final a = baru();
      await a.muatData();
      await a.register('Ari', 'ari@test.id', 'rahasia1');
      expect(await a.login('ari@test.id', 'salah'), 'Email atau password salah');
      expect(await a.login('tak@ada.id', 'rahasia1'), 'Email atau password salah');
      expect(a.isLoggedIn, isFalse);
    });

    test('sesi dipulihkan setelah dimuat ulang dan akun tetap ada', () async {
      final a = baru();
      await a.muatData();
      await a.register('Ari', 'ari@test.id', 'rahasia1');
      await a.login('ari@test.id', 'rahasia1');

      final b = baru();
      await b.muatData();
      expect(b.currentUser?.email, 'ari@test.id');
      b.logout();
      final c = baru();
      await c.muatData();
      expect(c.isLoggedIn, isFalse);
      expect(await c.login('ari@test.id', 'rahasia1'), isNull); // akun tidak hilang
    });

    test('migrasi akun lama (password polos): di-hash, plaintext hilang, tetap bisa masuk', () async {
      final lama = jsonEncode([
        {'id': '1', 'nama': 'Lama', 'email': 'lama@test.id', 'password': 'passwordlama'},
      ]);
      SharedPreferences.setMockInitialValues({'tripin_users': lama});

      final a = baru();
      await a.muatData();

      final mentah = await isiPrefsUsers();
      expect(mentah.contains('passwordlama'), isFalse);
      expect(mentah.contains('"password"'), isFalse);
      expect(mentah, contains('pbkdf2'));
      expect(await a.login('lama@test.id', 'passwordlama'), isNull);
      expect(a.currentUser?.id, '1');
    });

    test('dikunci 30 detik setelah 5 kali gagal, lalu bisa lagi', () async {
      var jam = DateTime(2026, 10, 3, 10);
      final a = baru(sekarang: () => jam);
      await a.muatData();
      await a.register('Ari', 'ari@test.id', 'rahasia1');

      for (var i = 0; i < 4; i++) {
        expect(await a.login('ari@test.id', 'salah'), 'Email atau password salah');
      }
      expect(await a.login('ari@test.id', 'salah'), contains('Terlalu banyak percobaan'));
      // password benar pun ditolak selama dikunci
      expect(await a.login('ari@test.id', 'rahasia1'), contains('Terlalu banyak percobaan'));
      expect(a.isLoggedIn, isFalse);

      jam = jam.add(const Duration(seconds: 31));
      expect(await a.login('ari@test.id', 'rahasia1'), isNull);
    });

    test('kunci per email: akun lain tidak ikut terkunci', () async {
      final a = baru();
      await a.muatData();
      await a.register('Ari', 'ari@test.id', 'rahasia1');
      await a.register('Budi', 'budi@test.id', 'rahasia2');
      for (var i = 0; i < 5; i++) {
        await a.login('ari@test.id', 'salah');
      }
      expect(await a.login('budi@test.id', 'rahasia2'), isNull);
    });

    test('hash otomatis diperbarui saat login bila iterasi sudah dinaikkan', () async {
      final lemah = baru(hasher: const PasswordHasher(pakaiIsolate: false, iterasi: 2));
      await lemah.muatData();
      await lemah.register('Ari', 'ari@test.id', 'rahasia1');
      expect((await isiPrefsUsers()), contains(r'pbkdf2$2$'));

      final kuat = baru(hasher: const PasswordHasher(pakaiIsolate: false, iterasi: 8));
      await kuat.muatData();
      expect(await kuat.login('ari@test.id', 'rahasia1'), isNull);
      expect((await isiPrefsUsers()), contains(r'pbkdf2$8$'));
    });
  });

  test('User.fromJson membaca data lama dan toJson tidak pernah menulis password polos', () {
    final u = User.fromJson({'id': '1', 'nama': 'A', 'email': 'a@b.id', 'password': 'rahasia'});
    expect(u.passwordLama, 'rahasia');
    expect(u.toJson().containsKey('password'), isFalse);
  });

  group('AuthProvider dengan repository lain (calon Firebase)', () {
    test('mendelegasikan pemulihan sesi, daftar, masuk, dan keluar', () async {
      final repo = _RepoPalsu();
      final auth = AuthProvider(repository: repo);
      var diberitahu = 0;
      auth.addListener(() => diberitahu++);

      await auth.muatData();
      expect(auth.isLoading, isFalse);
      expect(auth.isLoggedIn, isFalse);

      expect(await auth.register('Budi', 'budi@x.id', 'pw12345'), isNull);
      expect(await auth.register('Budi', 'budi@x.id', 'pw12345'), 'Email sudah terdaftar');

      expect(await auth.login('budi@x.id', 'salah'), 'Email atau password salah');
      expect(auth.isLoggedIn, isFalse);
      expect(await auth.login('budi@x.id', 'pw12345'), isNull);
      expect(auth.currentUser!.email, 'budi@x.id');

      auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(repo.keluarDipanggil, 1);
      expect(diberitahu, greaterThanOrEqualTo(3));
    });

    test('sesi dari repository dipulihkan saat muatData', () async {
      final repo = _RepoPalsu(sesi: const User(id: 'u9', nama: 'Sari', email: 's@x.id', passwordHash: ''));
      final auth = AuthProvider(repository: repo);
      await auth.muatData();
      expect(auth.currentUser!.id, 'u9');
    });
  });
}

class _RepoPalsu implements AuthRepository {
  final User? sesi;
  final _akun = <String, String>{};
  int keluarDipanggil = 0;

  _RepoPalsu({this.sesi});

  @override
  Future<User?> pulihkanSesi() async => sesi;

  @override
  Future<String?> daftar(String nama, String email, String password) async {
    if (_akun.containsKey(email)) return 'Email sudah terdaftar';
    _akun[email] = password;
    return null;
  }

  @override
  Future<HasilMasuk> masuk(String email, String password) async {
    if (_akun[email] != password) return const HasilMasuk.gagal('Email atau password salah');
    return HasilMasuk.berhasil(User(id: 'u1', nama: 'Budi', email: email, passwordHash: ''));
  }

  @override
  Future<void> keluar() async => keluarDipanggil++;
}
