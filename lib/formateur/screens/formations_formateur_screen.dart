import 'package:flutter/material.dart';

class FormationsFormateurScreen extends StatelessWidget {
  const FormationsFormateurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A110E),
        title: const Text('Mes Formations', style: TextStyle(color: Color(0xFFE5C158), fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _CourseItemCard(
            title: 'Executive MBA - Leadership',
            students: '38',
            volume: '60 h',
            room: 'Amphi B',
            status: 'En cours',
            statusColor: Colors.green,
          ),
          SizedBox(height: 16),
          _CourseItemCard(
            title: 'Master 2 Finance d\'Entreprise',
            students: '25',
            volume: '45 h',
            room: 'Lab 204',
            status: 'À venir',
            statusColor: Colors.amber,
          ),
        ],
      ),
    );
  }
}

class _CourseItemCard extends StatelessWidget {
  final String title;
  final String students;
  final String volume;
  final String room;
  final String status;
  final Color statusColor;

  const _CourseItemCard({
    required this.title,
    required this.students,
    required this.volume,
    required this.room,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1578716C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A1B16),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoColumn('Étudiants', students),
                _infoColumn('Volume', volume),
                _infoColumn('Salle', room),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF78716C))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2A1B16))),
      ],
    );
  }
}