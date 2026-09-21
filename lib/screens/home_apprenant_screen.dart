import 'package:flutter/material.dart';

class HomeApprenantScreen extends StatefulWidget {
  const HomeApprenantScreen({super.key});

  @override
  State<HomeApprenantScreen> createState() => _HomeApprenantScreenState();
}

class _HomeApprenantScreenState extends State<HomeApprenantScreen> {
  int _selectedIndex = 0;

  // Liste des écrans principaux associés à la navigation
  final List<Widget> _pages = [
    const DashboardHomeTab(),
    const FormationsTab(),
    const FinancesTab(),
    const NotificationsTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YMS - Espace Apprenant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Naviguer vers les notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // TODO: Ouvrir le Chatbot
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Nom de l\'Apprenant'),
              accountEmail: Text('apprenant@yms.mg'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.amber,
                child: Text('A', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
              ),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Formations'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendrier des séances'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers le calendrier
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Finances & Écolage'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text('Mes Certificats'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers les certificats
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Actualités'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers les actualités
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mon Profil'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Formations'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Finances'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ---------------------------------------------------------
// Sous-onglets de l'application
// ---------------------------------------------------------

class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue sur votre espace YMS !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text('Retrouvez ici vos formations en cours, vos échéances et les actualités.'),
          ],
        ),
      ),
    );
  }
}

// Modèle de formation
class Formation {
  final String id;
  final String titre;
  final String description;
  final double tarif;
  final String dates;
  final int capaciteRestante;

  Formation({
    required this.id,
    required this.titre,
    required this.description,
    required this.tarif,
    required this.dates,
    required this.capaciteRestante,
  });
}

class FormationsTab extends StatelessWidget {
  const FormationsTab({super.key});

  // Liste sans "const" global pour éviter les erreurs de compilation
  static final List<Formation> _formations = [
    Formation(
      id: '1',
      titre: 'Développement Web Full-Stack (React & Spring Boot)',
      description: 'Maîtrisez le développement d\'applications web modernes de bout en bout.',
      tarif: 350000,
      dates: 'Du 01 Oct 2026 au 15 Déc 2026',
      capaciteRestante: 5,
    ),
    Formation(
      id: '2',
      titre: 'Applications Mobiles avec Flutter & Dart',
      description: 'Créez des applications multiplateformes performantes et fluides.',
      tarif: 300000,
      dates: 'Du 10 Oct 2026 au 20 Jan 2027',
      capaciteRestante: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _formations.length,
      itemBuilder: (context, index) {
        final formation = _formations[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formation.titre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 6),
                Text(formation.description, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tarif : ${formation.tarif} Ar', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Chip(
                      label: Text('Reste : ${formation.capaciteRestante}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: formation.capaciteRestante > 3 ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('📅 ${formation.dates}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FinancesTab extends StatelessWidget {
  const FinancesTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Gestion des écolages et paiements'));
}

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Liste des notifications'));
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profil et paramètres du compte'));
}