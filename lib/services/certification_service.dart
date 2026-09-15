import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CertificationService {
  // 10.0.2.2 pour l'émulateur Android, ou localhost / ton IP locale
  final String baseUrl = "http://localhost:8081/api/v1/certifications";

  Future<File?> downloadCertificate(int userId, int formationId) async {
    try {
      final url = Uri.parse('$baseUrl/download/$userId/$formationId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/certificat_$formationId.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        return null;
      }
    } catch (e) {
      print("Erreur réseau / téléchargement : $e");
      return null;
    }
  }
}