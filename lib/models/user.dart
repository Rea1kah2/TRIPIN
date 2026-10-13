class User {
  final String id;
  final String nama;
  final String email;

  /// Hash PBKDF2 (lihat `PasswordHasher`). Password polos tidak pernah disimpan.
  final String passwordHash;

  /// Hanya terisi saat membaca data lama yang masih menyimpan password polos; `AuthProvider`
  /// langsung meng-hash-nya dan menyimpan ulang, jadi field ini tidak pernah ditulis kembali.
  final String? passwordLama;

  const User({
    required this.id,
    required this.nama,
    required this.email,
    this.passwordHash = '',
    this.passwordLama,
  });

  User copyWith({String? passwordHash, bool hapusPasswordLama = false}) => User(
        id: id,
        nama: nama,
        email: email,
        passwordHash: passwordHash ?? this.passwordHash,
        passwordLama: hapusPasswordLama ? null : passwordLama,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'passwordHash': passwordHash,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        nama: json['nama'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String? ?? '',
        passwordLama: json['password'] as String?,
      );
}
