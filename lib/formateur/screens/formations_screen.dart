import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/formateur_model.dart';
import '../../providers/formateur_provider.dart';
import '../../services/api_client.dart';
import '../../services/formateur_service.dart';
import '../widgets/formateur_colors.dart';
import '../widgets/formateur_common.dart';


class _Statut {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  const _Statut(this.label, this.bg, this.fg, this.border);
}

const _statuts = <String, _Statut>{
  'A_VENIR': _Statut('À venir', FormateurColors.bg, FormateurColors.gold, FormateurColors.border),
  'EN_COURS': _Statut('En cours', Color(0xFFECFDF5), FormateurColors.emerald, Color(0xFFA7F3D0)),
  'TERMINEE': _Statut('Terminée', Color(0xFFF3F4F6), Color(0xFF4B5563), Color(0xFFE5E7EB)),
  'ANNULEE': _Statut('Annulée', Color(0xFFFFF1F2), Color(0xFFBE123C), Color(0xFFFECDD3)),
};

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  bool _loading = true;
  String _error = '';
  List<Formation> _formations = [];
  String _search = '';
  bool _cards = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final email = context.read<FormateurProvider>().email;
    final apiClient = context.read<ApiClient>();
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await FormateurService.formations(apiClient, email);
      if (!mounted) return;
      setState(() => _formations = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erreur lors du chargement de vos formations : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Formation> get _filtered {
    final q = _search.toLowerCase();
    return _formations
        .where((f) =>
            f.titre.toLowerCase().contains(q) ||
            f.categorie.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return RefreshIndicator(
        color: FormateurColors.gold,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            PageHeader(
              title: 'Mes Formations',
              badge: '${list.length} dispensée${list.length > 1 ? 's' : ''}',
              subtitle:
                  'Gérez les cours et le suivi des apprenants qui vous sont assignés.',
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: SearchField(
                  hint: 'Rechercher par titre, catégorie...',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: FormateurColors.ink,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _cards = !_cards),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                        _cards ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 22),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (_error.isNotEmpty) ...[
              ErrorView(_error, onRetry: _load),
              const SizedBox(height: 12),
            ],
            if (_loading)
              const LoadingView('Chargement de vos formations...')
            else if (list.isEmpty)
              EmptyView(
                icon: Icons.menu_book_rounded,
                title: 'Aucune formation assignée',
                message: _search.isNotEmpty
                    ? 'Aucune formation ne correspond à votre recherche.'
                    : "Vous n'avez actuellement aucun cours attribué dans le système.",
              )
            else
              for (final f in list) _cards ? _card(f) : _row(f),
          ],
        ),
      );
  }

  _Statut _statutOf(Formation f) =>
      _statuts[f.statut] ??
      _Statut(f.statut, const Color(0xFFF3F4F6), const Color(0xFF374151),
          const Color(0xFFE5E7EB));

  Widget _progress(Formation f, {bool thin = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: const [
              Icon(Icons.groups_rounded, size: 13, color: FormateurColors.gold),
              SizedBox(width: 4),
              Text('Apprenants',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: FormateurColors.muted)),
            ]),
            Text('${f.occupees} / ${f.capaciteMax} (${f.progression}%)',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: FormateurColors.gold)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: f.progression / 100,
            minHeight: thin ? 6 : 8,
            backgroundColor: FormateurColors.bg,
            valueColor: const AlwaysStoppedAnimation(FormateurColors.gold),
          ),
        ),
      ],
    );
  }

  Widget _card(Formation f) {
    final st = _statutOf(f);
    final initials = f.titre.length >= 2
        ? f.titre.substring(0, 2).toUpperCase()
        : 'FM';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [FormateurColors.gold, FormateurColors.accent, FormateurColors.gold]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${f.id.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: FormateurColors.muted)),
                    StatusBadge(
                        label: st.label,
                        background: st.bg,
                        foreground: st.fg,
                        border: st.border),
                  ],
                ),
                const SizedBox(height: 10),
                Text(f.titre,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: FormateurColors.ink)),
                const SizedBox(height: 8),
                Wrap(spacing: 10, runSpacing: 6, children: [
                  _chip(Icons.sell_outlined, f.categorie),
                  _chip(Icons.schedule, '${f.dureeHeures}h'),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 12, color: FormateurColors.gold),
                  const SizedBox(width: 5),
                  Text('${f.dateDebut}  →  ${f.dateFin}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: FormateurColors.muted)),
                ]),
                const SizedBox(height: 12),
                _progress(f),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FormateurColors.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: FormateurColors.goldBorder),
                    ),
                    child: Text(initials,
                        style: const TextStyle(
                            color: FormateurColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Module YMS',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: FormateurColors.ink)),
                        Text('Formateur',
                            style: TextStyle(
                                fontSize: 10, color: FormateurColors.muted)),
                      ],
                    ),
                  ),
                  Material(
                    color: FormateurColors.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_forward,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FormateurColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FormateurColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: FormateurColors.gold),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: FormateurColors.muted)),
      ]),
    );
  }

  Widget _row(Formation f) {
    final st = _statutOf(f);
    final initials = f.titre.length >= 2
        ? f.titre.substring(0, 2).toUpperCase()
        : 'FM';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FormateurColors.ink,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FormateurColors.goldBorder),
              ),
              child: Text(initials,
                  style: const TextStyle(
                      color: FormateurColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: FormateurColors.ink)),
                  const SizedBox(height: 3),
                  Text(
                      '${f.categorie} • ${f.dureeHeures} h • ${f.dateDebut} au ${f.dateFin}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FormateurColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(
                label: st.label,
                background: st.bg,
                foreground: st.fg,
                border: st.border),
          ]),
          const SizedBox(height: 12),
          _progress(f, thin: true),
        ],
      ),
    );
  }
}
