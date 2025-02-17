import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_page.dart';

const String apiBaseUrl = 'http://192.168.9.121:8000';

class AnalyzeImagePage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String roleName;
  const AnalyzeImagePage({
    Key? key,
    required this.userId,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.roleName = '',
  }) : super(key: key);
  @override
  _AnalyzeImagePageState createState() => _AnalyzeImagePageState();
}

class _AnalyzeImagePageState extends State<AnalyzeImagePage> {
  File? _image;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();
  String _result = "Aucune analyse effectuée.";
  bool _isLoading = false;

  Future<File> _convertToPng(File imageFile) async {
    final originalImage = imageFile.readAsBytesSync();
    final decodedImage = img.decodeImage(originalImage);
    final pngImage = img.encodePng(decodedImage!);
    final convertedFile = File('${imageFile.path}.png');
    await convertedFile.writeAsBytes(pngImage);
    return convertedFile;
  }

  void _formatResult(String rawResult) {
    print("🔍 Réponse brute reçue : $rawResult"); // Debugging

    try {
      final correctedJson =
          utf8.decode(utf8.encode(rawResult)); // ✅ Corriger encodage UTF-8
      final decodedResponse = jsonDecode(correctedJson);
      print("✅ JSON décodé avec succès : $decodedResponse");

      if (decodedResponse.containsKey('result') &&
          decodedResponse['result'].containsKey('predictions')) {
        setState(() {
          _result = "Résultat de l'analyse :\n" +
              (decodedResponse['result']['predictions'] as List)
                  .map((prediction) =>
                      "- ${prediction['className']}: ${(prediction['probability']).toStringAsFixed(2)}%")
                  .join("\n");
        });
      } else {
        print("⚠️ Structure inattendue dans la réponse !");
        setState(() {
          _result = "Erreur lors du traitement des résultats.";
        });
      }
    } catch (e) {
      print("❌ Erreur de parsing JSON : $e");
      setState(() {
        _result = "Erreur lors de l'analyse : format des données inattendu.";
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null && _webImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucune image sélectionnée pour l\'analyse.')),
      );
      return;
    }

    if (loggedInUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur non connecté.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      File? convertedImage;

      if (!kIsWeb && _image != null) {
        convertedImage = await _convertToPng(_image!);
      }

      final uploadUrl = Uri.parse('$apiBaseUrl/upload');
      final uploadRequest = http.MultipartRequest('POST', uploadUrl);

      if (loggedInUserId != null) {
        uploadRequest.fields['utilisateur_id'] = loggedInUserId.toString();
      }

      if (kIsWeb && _webImageBytes != null) {
        uploadRequest.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImageBytes!,
            filename: 'image.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      } else if (convertedImage != null) {
        uploadRequest.files.add(
          http.MultipartFile.fromBytes(
            'image',
            convertedImage.readAsBytesSync(),
            filename: 'image.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      }

      uploadRequest.fields['utilisateur_id'] = loggedInUserId.toString();
      final uploadResponse = await uploadRequest.send();

      if (uploadResponse.statusCode != 201) {
        final responseBody = await uploadResponse.stream.bytesToString();
        throw Exception(
            'Erreur lors de l\'upload : ${uploadResponse.statusCode}');
      }

      final uploadResponseBody = await uploadResponse.stream.bytesToString();
      final uploadData = jsonDecode(uploadResponseBody);
      final uploadId = uploadData['image']['id'];

      final analyzeUrl = Uri.parse('$apiBaseUrl/predict');
      final analyzeRequest = http.MultipartRequest('POST', analyzeUrl);

      if (kIsWeb && _webImageBytes != null) {
        analyzeRequest.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImageBytes!,
            filename: 'image.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      } else if (convertedImage != null) {
        analyzeRequest.files.add(
          http.MultipartFile.fromBytes(
            'image',
            convertedImage.readAsBytesSync(),
            filename: 'image.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      }

      analyzeRequest.fields['upload_id'] = uploadId.toString();
      final analyzeResponse = await analyzeRequest.send();

      if (analyzeResponse.statusCode == 200) {
        final analyzeResponseBody =
            await analyzeResponse.stream.bytesToString();
        _formatResult(analyzeResponseBody);
      } else {
        final responseBody = await analyzeResponse.stream.bytesToString();
        throw Exception(
            'Erreur lors de l\'analyse : ${analyzeResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        _result = "Erreur : $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page principale',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15),
              Text(
                'Importez ou prenez une photo pour analyser l\'image.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 40),
              _image != null || _webImageBytes != null
                  ? Container(
                      height: 350,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: kIsWeb
                          ? Image.memory(
                              _webImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              _image!,
                              fit: BoxFit.cover,
                            ),
                    )
                  : Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                      child: Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 100,
                      ),
                    ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: Icon(
                      Icons.photo_library,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Galerie',
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
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Caméra',
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _analyzeImage,
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        'Analyser',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                _result,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
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
