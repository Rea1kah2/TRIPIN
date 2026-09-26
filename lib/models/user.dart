class User {
  final String id;
  final String nama;
  final String email;
  final String password;

  const User({
    required this.id,
    required this.nama,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'password': password,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        nama: json['nama'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
      );
}
