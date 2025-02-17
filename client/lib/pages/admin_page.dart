import 'package:flutter/material.dart';
import 'package:client/model/user.dart';
import 'package:client/services/user_service.dart';
import 'package:client/pages/edit_users.dart';
import 'package:client/pages/add_users.dart';

class AdminPage extends StatelessWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String roleName;

  const AdminPage({
    super.key,
    required this.userId,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.roleName = '',
  });

  @override
  Widget build(BuildContext context) {
    print('AdminPage - Role reçu : $roleName');
    print('AdminPage - ID utilisateur : $userId');
    print('AdminPage - Prénom : $firstName');
    print('AdminPage - Nom : $lastName');
    print('AdminPage - Email : $email');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'Gestion des Utilisateurs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      endDrawer: Drawer(
        child: Material(
          color: Colors.blueGrey.shade800,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  '$firstName $lastName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  email,
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    firstName[0] + lastName[0],
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.blueGrey.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.white),
                title: Text(
                  'ID Utilisateur: $userId',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              _buildDrawerItem(
                context,
                Icons.home,
                'Page Principale',
                null,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/analyse',
                    arguments: {
                      'userId': userId,
                      'firstName': firstName,
                      'lastName': lastName,
                      'email': email,
                      'roleName': roleName,
                    },
                  );
                },
              ),
              _buildDrawerItem(
                context,
                Icons.edit,
                'Modifier le Profil',
                null,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/updateProfile',
                    arguments: {
                      'userId': userId,
                      'firstName': firstName,
                      'lastName': lastName,
                      'email': email,
                    },
                  );
                },
              ),
              if (roleName.toUpperCase() == 'ADMIN')
                _buildDrawerItem(
                  context,
                  Icons.admin_panel_settings,
                  'Page Admin',
                  '/admin',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/admin',
                      arguments: {
                        'userId': userId,
                        'firstName': firstName,
                        'lastName': lastName,
                        'email': email,
                        'roleName': roleName,
                      },
                    );
                  },
                ),
              _buildDrawerItem(
                context,
                Icons.history,
                'Historique',
                '/historique',
                onTap: () {
                  Navigator.pushNamed(context, '/historique', arguments: {
                    'userId': userId,
                    'firstName': firstName,
                    'lastName': lastName,
                    'email': email,
                    'roleName': roleName,
                  });
                },
              ),
              _buildDrawerItem(
                context,
                Icons.group,
                'Mes Amis',
                '/friends',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/friends',
                    arguments: {
                      'userId': userId,
                      'firstName': firstName,
                      'lastName': lastName,
                      'email': email,
                      'roleName': roleName,
                    },
                  );
                },
              ),
              _buildDrawerItem(
                context,
                Icons.logout,
                'Se Déconnecter',
                null,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<List<User>>(
          future: fetchUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun utilisateur trouvé',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            } else {
              final users = snapshot.data!;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          user.firstName[0] + user.lastName[0],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        ),
                      ),
                      title: Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.email,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.verified_user,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Rôle : ${user.roleName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: PopupMenuButton<int>(
                        onSelected: (value) async {
                          if (value == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditUserPage(user: user),
                              ),
                            );
                          } else if (value == 2) {
                            await deleteUser(user.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Utilisateur supprimé'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 1,
                            child: ListTile(
                              leading: Icon(Icons.edit, color: Colors.blue),
                              title: Text('Modifier'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 2,
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Supprimer'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserPage()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, String? route,
      {void Function()? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onTap: onTap ?? () => Navigator.pushNamed(context, route ?? ''),
    );
  }
}
