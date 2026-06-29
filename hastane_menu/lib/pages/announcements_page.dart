import 'package:flutter/material.dart';
import 'package:hastane_menu/components/announcement_card.dart';
import 'package:hastane_menu/components/async_status.dart';
import 'package:hastane_menu/components/empty_state.dart';
import 'package:hastane_menu/core/constants/app_typography.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/announcement_service.dart';
import 'package:hastane_menu/models/announcement.dart';

/// Tüm duyuruların listelendiği sayfa. Veri kaynağı [AnnouncementService]
/// (dummy/remote'u oturuma+config'e göre seçer).
class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final AnnouncementService _service = $get<AnnouncementService>();
  late Future<List<Announcement>> _future = _service.all();

  void _reload() {
    setState(() => _future = _service.all(forceRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('📢 Tüm Duyurular', style: AppTypography.headingLarge),
          ),
          Expanded(
            child: FutureBuilder<List<Announcement>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: MenuLoadingCard(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MenuErrorCard(
                      title: 'Duyurular yüklenemedi',
                      message: '${snapshot.error}',
                      onRetry: _reload,
                    ),
                  );
                }
                final items = snapshot.data ?? const <Announcement>[];
                if (items.isEmpty) {
                  return const EmptyState(
                    emoji: '📭',
                    title: 'Henüz duyuru yok',
                    message: 'Yeni duyurular eklendiğinde burada görünecek.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      for (final a in items) AnnouncementCard(announcement: a),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
