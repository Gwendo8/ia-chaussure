import 'package:flutter/material.dart';
import 'package:client/model/user.dart';
import 'package:client/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditUserPage extends StatefulWidget {
  final User user;

  const EditUserPage({super.key, required this.user});

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  List<String> _roles = [];
  String? _selectedRole;

  @override
  void initState() {
    super.initState();

    _lastNameController = TextEditingController(text: widget.user.lastName);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController(text: widget.user.password);

    _selectedRole = widget.user.roleName;

    fetchRoles().then((roles) {
      setState(() {
        _roles = roles;
        if (_roles.contains(widget.user.roleName)) {
          _selectedRole = widget.user.roleName;
        } else {
          _selectedRole = _roles.isNotEmpty ? _roles.first : null;
        }
      });
    });
  }

  Future<void> updateUser() async {
    if (_selectedRole == null || !_roles.contains(_selectedRole)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selected role is not valid'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final updatedUser = {
      'last_name': _lastNameController.text,
      'first_name': _firstNameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': _selectedRole,
    };

    try {
      final response = await http.put(
        Uri.parse('http://192.168.9.121:8000/api/users/${widget.user.id}'),
        body: json.encode(updatedUser),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User updated successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      } else {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to update user'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modifier l\'utilisateur',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                "Modification des informations de l'utilisateur",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 80),
              buildInputField(
                controller: _lastNameController,
                label: 'Nom',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              buildInputField(
                controller: _firstNameController,
                label: 'Prénom',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              buildInputField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              buildInputField(
                controller: _passwordController,
                label: 'Mot de passe',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_roles.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Rôle',
                    prefixIcon: const Icon(Icons.admin_panel_settings,
                        color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _roles.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: updateUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Center(
                  child: Text(
                    'Modifier',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
