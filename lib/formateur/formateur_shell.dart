import 'package:flutter/material.dart';
import 'screens/home_formateur_screen.dart';
import 'screens/elearning_formateur_screen.dart';
import 'screens/formations_formateur_screen.dart';
import 'screens/presence_formateur_screen.dart';
import 'screens/profile_formateur_screen.dart';

class FormateurShell extends StatefulWidget {
  const FormateurShell({super.key});

  @override
  State<FormateurShell> createState() => _FormateurShellState();
}

class _FormateurShellState extends State<FormateurShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeFormateurScreen(onNavigate: (index) => setState(() => _currentIndex = index)),
      const ElearningFormateurScreen(),
      const FormationsFormateurScreen(),
      const PresenceFormateurScreen(),
      const ProfileFormateurScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A110E),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A110E),
          border: Border(
            top: BorderSide(color: Color(0x33C5A059), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Accueil'),
            _buildNavItem(1, Icons.menu_book_rounded, 'E-Learning'),
            Transform.translate(
              offset: const Offset(0, -10),
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9A7936), Color(0xFFC5A059), Color(0xFFE5C158)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A110E), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1A110E), size: 24),
                ),
              ),
            ),
            _buildNavItem(2, Icons.folder_rounded, 'Formations'),
            _buildNavItem(4, Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFFC5A059) : const Color(0xFF78716C);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}