import 'package:flutter/material.dart';

import 'formateur_colors.dart';

const kCardRadius = 20.0;

BoxDecoration cardDecoration({Color color = Colors.white}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(kCardRadius),
  border: Border.all(color: FormateurColors.border),
);

/// En-tête de page : petit label doré + titre + sous-titre.
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome, size: 15, color: FormateurColors.gold),
            SizedBox(width: 6),
            Text(
              'ESPACE FORMATEUR',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900,
                color: FormateurColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: FormateurColors.ink,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FormateurColors.border),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: FormateurColors.gold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: FormateurColors.muted,
          ),
        ),
      ],
    );
  }
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final bool dark;
  final Color? iconColor;
  final double size;
  const IconBox({
    super.key,
    required this.icon,
    this.dark = false,
    this.iconColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? FormateurColors.ink : FormateurColors.bg,
        borderRadius: BorderRadius.circular(size * 0.33),
        border: Border.all(
          color: dark ? FormateurColors.goldBorder : FormateurColors.border,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color:
            iconColor ?? (dark ? FormateurColors.accent : FormateurColors.gold),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool dark;
  final Color valueColor;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.dark = false,
    this.valueColor = FormateurColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                    color: FormateurColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          IconBox(icon: icon, dark: dark, size: 38),
        ],
      ),
    );
  }
}

/// Grille 2 colonnes de cartes statistiques (adaptée au mobile).
class StatGrid extends StatelessWidget {
  final List<StatCard> cards;
  const StatGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < cards.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final Color? dot;
  const StatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border ?? Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: FormateurColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: FormateurColors.muted, fontSize: 13),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: FormateurColors.muted,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FormateurColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FormateurColors.gold),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  final String message;
  const LoadingView(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: cardDecoration(),
      child: Column(
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: FormateurColors.gold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: FormateurColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView(this.message, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: FormateurColors.rose, width: 4),
          top: BorderSide(color: FormateurColors.border),
          right: BorderSide(color: FormateurColors.border),
          bottom: BorderSide(color: FormateurColors.border),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: FormateurColors.rose,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: FormateurColors.ink,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: cardDecoration(),
      child: Column(
        children: [
          IconBox(icon: icon, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: FormateurColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FormateurColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille de session : horaires + titre (utilisée sur l'accueil et le calendrier).
class SeanceTile extends StatelessWidget {
  final String dayNumber;
  final String title;
  final String time;
  final Widget? trailing;
  const SeanceTile({
    super.key,
    required this.dayNumber,
    required this.title,
    required this.time,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FormateurColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FormateurColors.ink,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FormateurColors.goldBorder),
            ),
            child: Text(
              dayNumber,
              style: const TextStyle(
                color: FormateurColors.accent,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Formation' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: FormateurColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 13,
                      color: FormateurColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FormateurColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
