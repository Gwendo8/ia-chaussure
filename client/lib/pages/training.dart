import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageUpload extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String roleName;

  const ImageUpload({
    super.key,
    required this.userId,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.roleName = '',
  });

  @override
  _ImageUploadState createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  String _result = 'Ready to process';
  final TextEditingController _labelController =
      TextEditingController(); // Contrôleur pour l'étiquette

  @override
  void initState() {
    super.initState();
    // _requestPermissions();
  }

  // Fonction pour entraîner avec une seule image
  Future<void> _trainSingleImage() async {
    try {
      setState(() {
        _result = 'Opening file picker for a single image...';
      });

      // Récupérer l'étiquette depuis le champ de saisie
      final labelText = _labelController.text;
      if (labelText.isEmpty) {
        setState(() {
          _result = 'Please enter a label.';
        });
        return;
      }

      // Validation de l'étiquette
      final label = int.tryParse(labelText);
      if (label == null) {
        setState(() {
          _result = 'Invalid label. Please enter a valid integer.';
        });
        return;
      }

      // Permettre à l'utilisateur de choisir une image
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result == null) {
        setState(() {
          _result = 'No image selected.';
        });
        return;
      }

      final Uint8List fileBytes = result.files.single.bytes ??
          await File(result.files.single.path!).readAsBytes();
      final String fileName = result.files.single.name;

      if (fileBytes == null || fileName == null) {
        setState(() {
          _result = 'Failed to read the image.';
        });
        return;
      }

      setState(() {
        _result = 'Resizing image...';
      });

      // Redimensionner l'image
      Uint8List resizedImage = await _resizeImage(fileBytes, 224, 224);
      setState(() {
        _result = 'Image resized successfully. Sending to server...';
      });

      // Envoyer l'image et l'étiquette au backend
      final uri = Uri.parse('http://192.168.9.121:8000/train-single-image');
      final request = http.MultipartRequest('POST', uri)
        ..fields['label'] = label.toString()
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          resizedImage,
          filename: fileName,
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          _result = 'Training successful! Response: $responseBody';
        });
      } else {
        final errorResponse = await response.stream.bytesToString();
        setState(() {
          _result = 'Training failed. Server error: $errorResponse';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error during training: $e';
      });
    }
  }

  // Fonction pour redimensionner l'image
  Future<Uint8List> _resizeImage(
      Uint8List input, int targetWidth, int targetHeight) async {
    final decodedImage = img.decodeImage(input);
    if (decodedImage == null) throw Exception('Failed to decode image.');
    final resizedImage =
        img.copyResize(decodedImage, width: targetWidth, height: targetHeight);
    return Uint8List.fromList(img.encodeJpg(resizedImage));
  }

  // Future<void> _requestPermissions() async {
  //   if (await Permission.storage.request().isDenied) {
  //     setState(() {
  //       _result = 'Permission denied. Please allow permissions.';
  //     });
  //   }
  // }

  // Fonction pour entraîner avec un fichier ZIP
  Future<void> _pickAndTrainModel() async {
    try {
      setState(() {
        _result = 'Selecting a ZIP file...';
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null) {
        setState(() {
          _result = 'No file selected.';
        });
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null || !File(filePath).existsSync()) {
        setState(() {
          _result = 'Invalid file path.';
        });
        return;
      }

      final Uint8List fileBytes = await File(filePath).readAsBytes();
      final String fileName = result.files.single.name;

      setState(() {
        _result = 'Uploading ZIP file for training...';
      });

      final uri = Uri.parse('http://192.168.9.121:8000/train');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'dataset',
          fileBytes,
          filename: fileName!,
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          _result = 'Training completed successfully!';
        });
      } else {
        final errorResponse = await response.stream.bytesToString();
        setState(() {
          _result = 'Error during training: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Information"),
          content: const Text(
            "Les chiffres correspondent à :\n\n"
            "0 : Nike\n"
            "1 : Converse\n"
            "2 : Adidas",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Entraînement d'Image",
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _labelController,
                      decoration: InputDecoration(
                        labelText: 'Entrez une étiquette',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Colors.blueAccent),
                          onPressed: () => _showInfoDialog(context),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _trainSingleImage,
                      icon: const Icon(
                        Icons.image,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Entraîner une Image',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickAndTrainModel,
                      icon: const Icon(
                        Icons.folder_zip,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Entraîner un Fichier ZIP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.grey[200],
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 16),
                ),
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
