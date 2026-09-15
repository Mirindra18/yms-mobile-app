import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/certification_service.dart';

class CertificateScreen extends StatefulWidget {
  final int userId;
  final int formationId;

  const CertificateScreen({
    Key? key,
    required this.userId,
    required this.formationId,
  }) : super(key: key);

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final CertificationService _service = CertificationService();
  File? _pdfFile;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _fetchCertificate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final file = await _service.downloadCertificate(widget.userId, widget.formationId);

    setState(() {
      _isLoading = false;
      if (file != null) {
        _pdfFile = file;
      } else {
        _errorMessage = "Vous n'êtes pas encore éligible au certificat (Présence < 75% ou écolage non soldé).";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Certificat YMS"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _pdfFile != null
                ? PDFView(filePath: _pdfFile!.path)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _fetchCertificate,
                        child: const Text("Télécharger mon certificat"),
                      ),
                    ],
                  ),
      ),
    );
  }
}