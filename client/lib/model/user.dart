class User {
  final int id;
  final String lastName;
  final String firstName;
  final String email;
  final String roleName;
  final String password;

  User({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.email,
    required this.roleName,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['IDUser'].toString()) ?? 0,
      lastName: json['LastName'],
      firstName: json['FirstName'],
      email: json['Email'],
      roleName: json['roleName'] ?? '',
      password: json['Password'] ?? '',
    );
  }
}