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
          // Bouton de notification rapide avec badge potentiel
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Naviguer vers la liste des notifications
            },
          ),
          // Bouton Chatbot rapide
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // TODO: Ouvrir l'écran du Chatbot
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
                // TODO: Naviguer vers les certificats
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Actualités'),
              onTap: () {
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
                // TODO: Gérer la déconnexion et retourner à l'écran de Login
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
// Exemples de widgets temporaires pour les onglets
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

class FormationsTab extends StatelessWidget {
  const FormationsTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Liste des formations disponibles & Mes formations'));
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