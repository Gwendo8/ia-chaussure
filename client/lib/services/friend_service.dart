import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> fetchFriends(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('http://192.168.9.121:8000/api/friends/$userId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Erreur : ${response.statusCode}, ${response.body}');
      throw Exception('Erreur lors de la récupération des amis');
    }
  } catch (error) {
    print('Erreur réseau : $error');
    throw Exception('Erreur lors de la récupération des amis');
  }
}
