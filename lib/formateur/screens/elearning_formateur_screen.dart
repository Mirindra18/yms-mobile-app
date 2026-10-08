import 'package:flutter/material.dart';

class ElearningFormateurScreen extends StatelessWidget {
  const ElearningFormateurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A110E),
        title: const Text('Gestion E-Learning', style: TextStyle(color: Color(0xFFE5C158), fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Color(0xFFE5C158)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('CONTENUS NUMÉRIQUES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2A1B16), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          const _ElearningCard(
            title: 'Fondamentaux du Leadership moderne',
            type: 'Module 1 • Vidéo + Quiz',
            progress: 0.78,
            progressText: '78%',
            status: 'Actif',
            pendingSubmissions: '28/35 devoirs rendus',
          ),
          const SizedBox(height: 14),
          const _ElearningCard(
            title: 'Analyse Financière & Étude de cas',
            type: 'Module 2 • Support PDF',
            progress: 0.42,
            progressText: '42%',
            status: 'En révision',
            pendingSubmissions: '12/25 devoirs rendus',
          ),
        ],
      ),
    );
  }
}

class _ElearningCard extends StatelessWidget {
  final String title;
  final String type;
  final double progress;
  final String progressText;
  final String status;
  final String pendingSubmissions;

  const _ElearningCard({
    required this.title,
    required this.type,
    required this.progress,
    required this.progressText,
    required this.status,
    required this.pendingSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1578716C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9A7936))),
              Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2A1B16))),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF5EFF3),
            color: const Color(0xFFC5A059),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pendingSubmissions, style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))),
              TextButton(
                onPressed: () {},
                child: const Text('Évaluer →', style: TextStyle(color: Color(0xFF9A7936), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}