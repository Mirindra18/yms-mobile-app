import 'package:flutter/material.dart';

class PresenceFormateurScreen extends StatefulWidget {
  const PresenceFormateurScreen({super.key});

  @override
  State<PresenceFormateurScreen> createState() => _PresenceFormateurScreenState();
}

class _PresenceFormateurScreenState extends State<PresenceFormateurScreen> {
  bool _isQrMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A110E),
        title: const Text('Gestion des Présences', style: TextStyle(color: Color(0xFFE5C158), fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sélecteur de mode
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E5E4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isQrMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isQrMode ? const Color(0xFF1A110E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('QR Code Dynamique', style: TextStyle(color: _isQrMode ? const Color(0xFFE5C158) : const Color(0xFF78716C), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isQrMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isQrMode ? const Color(0xFF1A110E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('Empreinte', style: TextStyle(color: !_isQrMode ? const Color(0xFFE5C158) : const Color(0xFF78716C), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Contenu QR ou Empreinte
          if (_isQrMode) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x1578716C)),
              ),
              child: Column(
                children: [
                  const Text('Cours: MBA Executive • Session #08', style: TextStyle(color: Color(0xFF9A7936), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 16),
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A110E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFFC5A059)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Régénération automatique dans 28s', style: TextStyle(color: Color(0xFF78716C), fontSize: 11)),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x1578716C)),
              ),
              child: Column(
                children: const [
                  Text('Biométrie Formateur / Étudiant', style: TextStyle(color: Color(0xFF9A7936), fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 24),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF1A110E),
                    child: Icon(Icons.fingerprint, size: 50, color: Color(0xFFC5A059)),
                  ),
                  SizedBox(height: 20),
                  Text('Appuyez pour valider la présence', style: TextStyle(color: Color(0xFF78716C), fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}