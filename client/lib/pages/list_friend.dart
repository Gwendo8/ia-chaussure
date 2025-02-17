import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class FriendsPage extends StatefulWidget {
  final String? userId;
  final String firstName;
  final String lastName;
  final String email;
  final String roleName;

  const FriendsPage({
    super.key,
    required this.userId,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.roleName = '',
  });

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late Future<List<dynamic>> friends;

  Future<List<dynamic>> fetchFriends(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.9.121:8000/api/friends/$userId'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Aucun ami trouvé pour cet utilisateur.');
      } else {
        throw Exception('Erreur du serveur : ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Erreur lors de la connexion au serveur : $error');
    }
  }

  Future<void> addFriend(String friendId) async {
    if (friendId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Oops ! Vous ne pouvez pas vous ajouter vous-même en ami.')),
      );
      return; // Arrête l'exécution si l'utilisateur tente de s'ajouter lui-même
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.9.121:8000/api/friends'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': widget.userId, 'friendId': friendId}),
      );

      if (response.statusCode == 201) {
        setState(() {
          friends = fetchFriends(widget.userId!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ami ajouté avec succès !')),
        );
      } else if (response.statusCode == 400) {
        final errorMessage = json.decode(response.body)['error'];

        // Message d'erreur spécifique selon la réponse du serveur
        if (errorMessage.contains('vous-même')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Oops ! Vous ne pouvez pas vous ajouter vous-même en ami.')),
          );
        } else if (errorMessage.contains('existe déjà')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vous êtes déjà ami(e) avec cet utilisateur.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Demande invalide. Vérifiez les informations saisies.')),
          );
        }
      } else if (response.statusCode == 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vous êtes déjà ami(e) avec cet utilisateur.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erreur inconnue : ${response.statusCode}. Veuillez réessayer.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Une erreur réseau s\'est produite. Vérifiez votre connexion.')),
      );
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.9.121:8000/api/friends'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.userId,
          'friendId': friendId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          friends = fetchFriends(widget.userId!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ami supprimé avec succès')),
        );
      } else {
        final errorMessage =
            json.decode(response.body)['error'] ?? 'Erreur inconnue';
        throw Exception(errorMessage);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    }
  }

  void showFriendUploads(BuildContext context, String friendId) async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.9.121:8000/api/uploads/$friendId'));

      if (response.statusCode == 200) {
        final uploadsData = json.decode(response.body);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.88,
              minChildSize: 0.7,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: uploadsData.isEmpty
                      ? Center(
                          child: Text(
                            "Aucun historique trouvé.",
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: uploadsData.length,
                          itemBuilder: (context, index) {
                            final upload = uploadsData[index];
                            final imageUrl = 'https://192.168.9.121:8000/' +
                                upload['path'].replaceAll("\\", "/");

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 150,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                            Icons.image_not_supported,
                                            size: 50),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          upload['name'] ?? 'Inconnu',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          upload['category'] ??
                                              'Aucune catégorie',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                );
              },
            );
          },
        );
      } else {
        throw Exception('Aucun upload trouvé pour cet utilisateur.');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      friends = fetchFriends(widget.userId!);
    } else {
      friends = Future.error('Aucun ID utilisateur fourni');
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
        title: Text(
          'Mes amis',
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
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
                accountName: Text('${widget.firstName} ${widget.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(widget.email,
                    style: const TextStyle(color: Colors.white70)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    widget.firstName.isNotEmpty && widget.lastName.isNotEmpty
                        ? widget.firstName[0] + widget.lastName[0]
                        : '',
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
                  'ID Utilisateur: ${widget.userId}',
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
                      'userId': widget.userId,
                      'firstName': widget.firstName,
                      'lastName': widget.lastName,
                      'email': widget.email,
                      'roleName': widget.roleName,
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
                      'userId': widget.userId,
                      'firstName': widget.firstName,
                      'lastName': widget.lastName,
                      'email': widget.email,
                    },
                  );
                },
              ),
              if (widget.roleName == 'ADMIN')
                _buildDrawerItem(
                    context, Icons.admin_panel_settings, 'Page Admin', '/admin',
                    onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/admin',
                    arguments: {
                      'userId': widget.userId,
                      'firstName': widget.firstName,
                      'lastName': widget.lastName,
                      'email': widget.email,
                      'roleName': widget.roleName,
                    },
                  );
                }),
              _buildDrawerItem(
                  context, Icons.history, 'Historique', '/historique',
                  onTap: () {
                Navigator.pushNamed(
                  context,
                  '/historique',
                  arguments: {
                    'userId': widget.userId,
                    'firstName': widget.firstName,
                    'lastName': widget.lastName,
                    'email': widget.email,
                    'roleName': widget.roleName,
                  },
                );
              }),
              _buildDrawerItem(context, Icons.group, 'Mes Amis', '/friends',
                  onTap: () {
                Navigator.pushNamed(
                  context,
                  '/friends',
                  arguments: {
                    'userId': widget.userId,
                    'firstName': widget.firstName,
                    'lastName': widget.lastName,
                    'email': widget.email,
                    'roleName': widget.roleName,
                  },
                );
              }),
              _buildDrawerItem(context, Icons.logout, 'Se Déconnecter', null,
                  onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              }),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 114, 210, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: friends,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Erreur : ${snapshot.error}",
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    friends = fetchFriends(widget.userId!);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blueAccent,
                                ),
                                child: const Text("Réessayer"),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            "Aucun ami trouvé.",
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      final friendsList = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: friendsList.length,
                        itemBuilder: (context, index) {
                          final friend = friendsList[index];
                          final firstName = friend['FirstName'] ?? "Inconnu";
                          final lastName = friend['LastName'] ?? "Inconnu";

                          return Card(
                            elevation: 6,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  firstName[0].toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                "$firstName $lastName",
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == "history") {
                                    showFriendUploads(
                                        context, friend['FriendID'].toString());
                                  } else if (value == "delete") {
                                    removeFriend(friend['FriendID'].toString());
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: "history",
                                    child: Row(
                                      children: [
                                        Icon(Icons.history, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text("Historique"),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: "delete",
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text("Supprimer"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 - 30,
              child: FloatingActionButton(
                onPressed: () async {
                  final friendId = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      TextEditingController controller =
                          TextEditingController();
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Ajouter un ami',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.blueAccent,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Entrez l'ID de l'ami pour l'ajouter à votre liste.",
                              style: GoogleFonts.nunito(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'ID de l\'ami',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.nunito(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, controller.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Ajouter',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (friendId != null && friendId.isNotEmpty) {
                    addFriend(friendId);
                  }
                },
                backgroundColor: Colors.blueAccent,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.add, size: 28, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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
