import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class HistoriquePage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String roleName;

  const HistoriquePage({
    Key? key,
    required this.userId,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.roleName = '',
  }) : super(key: key);

  @override
  _HistoriquePageState createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  List<dynamic> allHistorique = [];
  List<dynamic> filteredHistorique = [];
  String? selectedFilter;

  Future<void> fetchHistorique() async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.9.121:8000/api/historique?userId=${widget.userId}'));

      if (response.statusCode == 200) {
        setState(() {
          allHistorique = json.decode(response.body);
          filteredHistorique = List.from(allHistorique);
        });
      } else {
        throw Exception('Erreur de récupération des données');
      }
    } catch (e) {
      print('Erreur : $e');
    }
  }

  void sortByName() {
    setState(() {
      filteredHistorique.sort((a, b) => a['name']
          .toString()
          .toLowerCase()
          .compareTo(b['name'].toString().toLowerCase()));
    });
  }

  void sortByCategory() {
    setState(() {
      filteredHistorique.sort((a, b) => a['category']
          .toString()
          .toLowerCase()
          .compareTo(b['category'].toString().toLowerCase()));
    });
  }

  void sortByDateAscending() {
    setState(() {
      filteredHistorique.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date_upload_iso']);
        DateTime dateB = DateTime.parse(b['date_upload_iso']);
        return dateA.compareTo(dateB);
      });
    });
  }

  void sortByDateDescending() {
    setState(() {
      filteredHistorique.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date_upload_iso']);
        DateTime dateB = DateTime.parse(b['date_upload_iso']);
        return dateB.compareTo(dateA);
      });
    });
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

  @override
  void initState() {
    super.initState();
    fetchHistorique();
  }

  @override
  Widget build(BuildContext context) {
    print('roleName: ${widget.roleName}');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Historique des chaussures',
            style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
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
                    style: TextStyle(fontWeight: FontWeight.bold)),
                accountEmail:
                    Text(widget.email, style: TextStyle(color: Colors.white70)),
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
                leading: Icon(Icons.info, color: Colors.white),
                title: Text(
                  'ID Utilisateur: ${widget.userId}',
                  style: TextStyle(color: Colors.white),
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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            height: 60,
            color: Colors.blueAccent.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredHistorique.length} chaussures trouvés',
                  style: GoogleFonts.nunito(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_list_outlined,
                    color: Colors.blueAccent,
                    size: 30,
                  ),
                  onPressed: () {
                    _openFilterOptions(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredHistorique.length,
              itemBuilder: (context, index) {
                final item = filteredHistorique[index];
                return HistoriqueCard(
                  item,
                  onDelete: (id) {
                    setState(() {
                      filteredHistorique
                          .removeWhere((element) => element['id'] == id);
                      allHistorique
                          .removeWhere((element) => element['id'] == id);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrer par',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.category, color: Colors.green),
                title: Text(
                  'Catégorie (ordre alphabétique)',
                  style: GoogleFonts.nunito(fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                  sortByCategory();
                },
              ),
              ListTile(
                leading: Icon(Icons.date_range, color: Colors.green),
                title: Text(
                  'Date (plus récent en premier)',
                  style: GoogleFonts.nunito(fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                  sortByDateDescending();
                },
              ),
              ListTile(
                leading: Icon(Icons.date_range, color: Colors.green),
                title: Text(
                  'Date (plus ancien en premier)',
                  style: GoogleFonts.nunito(fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                  sortByDateAscending();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class HistoriqueCard extends StatelessWidget {
  final Map itemData;
  final Function onDelete;

  const HistoriqueCard(this.itemData, {required this.onDelete});

  @override
  Widget build(BuildContext context) {
    String category = itemData['category'] ?? 'Non catégorisé';
    String dateUpload = itemData['date_upload'] ?? 'Date inconnue';
    double probability = 0.0;

    if (itemData.containsKey('probability') &&
        itemData['probability'] != null) {
      probability = (itemData['probability'] is String)
          ? double.tryParse(itemData['probability']) ?? 0.0
          : itemData['probability'].toDouble();
    }

    // Alternative si l'API renvoie predictions sous un objet JSON
    if (itemData.containsKey('predictions') &&
        itemData['predictions'] is List &&
        itemData['predictions'].isNotEmpty) {
      category = itemData['predictions'][0]['className'] ?? category;
      probability = itemData['predictions'][0]['probability'] ?? probability;
    }

    return Dismissible(
      key: Key(itemData['id'].toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        final id = itemData['id'];
        if (id != null) {
          try {
            final response = await http.delete(
              Uri.parse('http://192.168.9.121:8000/api/historique/$id'),
            );

            if (response.statusCode == 200) {
              print('Suppression réussie');
              onDelete(id);
            } else {
              print('Erreur lors de la suppression : ${response.statusCode}');
            }
          } catch (e) {
            print('Erreur : $e');
          }
        }
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: EdgeInsets.all(15),
        height: 370, // Ajustement de la hauteur pour inclure la date
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              spreadRadius: 4,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image de la chaussure
            Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                image: DecorationImage(
                  image: NetworkImage(itemData['path']),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            // Détails sous l'image
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    Text(
                      'Catégorie détectée : $category',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '$dateUpload',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
