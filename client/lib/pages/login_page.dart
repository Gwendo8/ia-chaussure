import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/pages/historique_page.dart';
import 'package:client/pages/register_page.dart';
import 'admin_page.dart';
import 'package:client/pages/forgot_password.dart';

const d_green = Color(0XFF54D3C2);
// Variable globale pour stocker l'ID utilisateur connecté
int? loggedInUserId;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _message = '';
      _isSuccess = false;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await http.post(
        // Uri.parse('http://10.11.24.181:8000/login'),
        Uri.parse('http://192.168.9.121:8000/login'),

        // pour le partage de co :  192.0.0.2
        // pour internet : 192.168.1.16
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        if (data['IDUser'] != null &&
            data['firstName'] != null &&
            data['lastName'] != null &&
            data['email'] != null &&
            data['roleName'] != null) {
          final userId = data['IDUser'];
          final roleName = data['roleName'];
          final firstName = data['firstName'];
          final lastName = data['lastName'];
          final email = data['email'];

          setState(() {
            _message = data['message'];
            _isSuccess = true;
            loggedInUserId = int.parse(data['IDUser']);
          });

          if (roleName.toUpperCase() == 'ADMIN') {
            if (userId != null &&
                firstName != null &&
                lastName != null &&
                email != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminPage(
                    userId: userId,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    roleName: roleName,
                  ),
                ),
              );
            } else {
              setState(() {
                _message =
                    'Certaines informations utilisateur sont manquantes.';
              });
            }
          } else if (roleName.toUpperCase() == 'USER') {
            if (userId != null &&
                firstName != null &&
                lastName != null &&
                email != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoriquePage(
                    userId: userId,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    roleName: roleName,
                  ),
                ),
              );
            } else {
              setState(() {
                _message =
                    'Certaines informations utilisateur sont manquantes.';
              });
            }
          }
        } else {
          setState(() {
            _message = 'Erreur : IDUser non fourni.';
            _isSuccess = false;
          });
        }
      } else {
        setState(() {
          _message = json.decode(response.body)['message'];
          _isSuccess = false;
        });
      }
    } catch (error) {
      setState(() {
        _message = 'Une erreur est survenue. Veuillez réessayer.';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Connexion",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 1),
                const Text(
                  'Connectez-vous',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Veuillez entrer vos informations pour accéder à votre compte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 325,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.email, color: Colors.blueAccent),
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 13, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 325,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.lock, color: Colors.blueAccent),
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 13, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    print('Mot de passe oublié cliqué');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage()),
                    );
                  },
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      color: d_green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text(
                          'Connexion',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
                const SizedBox(height: 20),
                if (_message.isNotEmpty)
                  Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('réussie')
                          ? Colors.green
                          : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    "Pas encore de compte ? Inscrivez-vous",
                    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
