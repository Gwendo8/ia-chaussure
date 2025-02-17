import 'package:flutter/material.dart';
import 'package:client/pages/analyze_image_page.dart';
import 'package:client/pages/login_page.dart';
import 'package:client/pages/register_page.dart';
import 'package:client/pages/home_page.dart';
import 'package:client/pages/admin_page.dart';
import 'package:client/pages/historique_page.dart';
import 'package:client/pages/training.dart';
import 'package:client/pages/update_profil.dart';
import 'package:client/pages/forgot_password.dart';
import 'package:client/pages/list_friend.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Mon Application',
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (context) => HomePage());
            case '/login':
              return MaterialPageRoute(builder: (context) => LoginPage());
            case '/register':
              return MaterialPageRoute(builder: (context) => RegisterPage());
            case '/admin':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => AdminPage(
                  userId: args['userId'],
                  firstName: args['firstName'],
                  lastName: args['lastName'],
                  email: args['email'],
                  roleName: args['roleName'],
                ),
              );
            case '/historique':
              final args = settings.arguments as Map<String, dynamic>;
              final userId = args['userId'];
              final firstName = args['firstName'];
              final lastName = args['lastName'];
              final email = args['email'];
              final roleName = args['roleName'];

              return MaterialPageRoute(
                builder: (context) => HistoriquePage(
                  userId: userId,
                  firstName: firstName,
                  lastName: lastName,
                  email: email,
                  roleName: roleName,
                ),
              );
            case '/updateProfile':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => UpdateProfilePage(
                  userId: args['userId'],
                  firstName: args['firstName'],
                  lastName: args['lastName'],
                  email: args['email'],
                ),
              );
            case '/analyse':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                  builder: (context) => AnalyzeImagePage(
                        userId: args['userId'],
                        firstName: args['firstName'],
                        lastName: args['lastName'],
                        email: args['email'],
                        roleName: args['roleName'],
                      ));

            case '/friends':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => FriendsPage(
                  userId: args['userId'],
                  firstName: args['firstName'],
                  lastName: args['lastName'],
                  email: args['email'],
                  roleName: args['roleName'],
                ),
              );
            default:
              return null;
          }
        });
  }
}
