import 'package:flutter/material.dart';

class ProfileFormateurScreen extends StatelessWidget {
  const ProfileFormateurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A110E),
        title: const Text('Profil Formateur', style: TextStyle(color: Color(0xFFE5C158), fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1B16), Color(0xFF1A110E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=300',
                  ),
                ),
                SizedBox(height: 12),
                Text('Dr. Valérie Laurent', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Professeur Titulaire & Consultant', style: TextStyle(color: Color(0xFFE5C158), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1578716C)),
            ),
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.person_outline, color: Color(0xFF9A7936)),
                  title: Text('Informations du compte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF78716C)),
                ),
                Divider(height: 1, color: Color(0xFFF5EFF3)),
                ListTile(
                  leading: Icon(Icons.fingerprint, color: Color(0xFF9A7936)),
                  title: Text('Sécurité & Biométrie', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF78716C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}