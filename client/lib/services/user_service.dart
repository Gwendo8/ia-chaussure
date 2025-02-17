import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/model/user.dart';

// Fonction pour récupérer les utilisateurs
Future<List<User>> fetchUsers() async {
  final response =
      await http.get(Uri.parse('http://192.168.9.121:8000/api/users'));

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);

    print(data);

    for (var userJson in data) {
      print(userJson['roleName']);
    }

    return data.map((json) => User.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load users');
  }
}

// Fonction pour récupérer les rôles
Future<List<String>> fetchRoles() async {
  final response =
      await http.get(Uri.parse('http://192.168.9.121:8000/api/roles'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    List<String> roles = List<String>.from(data.map((role) => role['Name']));
    print("Roles fetched: $roles");
    return roles;
  } else {
    throw Exception('Failed to load roles');
  }
}

// Fonction pour supprimer un utilisateur
Future<void> deleteUser(int userId) async {
  final response = await http.delete(
    Uri.parse('http://192.168.9.121:8000/api/users/$userId'),
  );
  if (response.statusCode == 200) {
    print('User deleted successfully');
  } else {
    print('Error: ${response.statusCode}');
    print('Response body: ${response.body}');
    throw Exception('Failed to delete user');
  }
}

// Fonction pour ajouter un utilisateur
Future<void> addUser(String lastName, String firstName, String email,
    String password, int idRole) async {
  final response = await http.post(
    Uri.parse('http://192.168.9.121:8000/api/addusers'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "lastName": lastName,
      "firstName": firstName,
      "email": email,
      "password": password,
      "idRole": idRole,
    }),
  );

  if (response.statusCode != 201) {
    throw Exception("Failed to add user: ${response.body}");
  }
}
