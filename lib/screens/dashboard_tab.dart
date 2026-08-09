import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/student_profile.dart';
import '../widgets/section_title.dart';
import '../widgets/empty_state.dart';
import 'messages_screen.dart';
import 'gallery_screen.dart';
import 'programs_screen.dart';
import 'notifications_screen.dart';

class DashboardTab extends StatefulWidget {
  final StudentProfile profile;
  const DashboardTab({super.key, required this.profile});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchUnreadCounts();
  }

  Future<void> _fetch() async {
    try {
      final data = await _client
          .from('announcements')
          .select('id, title, content, type, created_at')
          .order('created_at', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchUnreadCounts() async {
    final p = widget.profile;
    try {
      final sectionId = p.sectionId;
      final orFilters = [
        'target_user_id.eq.${p.id}',
        'target_role.eq.student',
        if (sectionId != null) 'target_section_id.eq.$sectionId',
      ].join(',');
      final notifCount = await _client
          .from('notifications')
          .select('id')
          .or(orFilters)
          .eq('is_read', false)
          .count(CountOption.exact);
      final msgCount = await _client
          .from('messages')
          .select('id')
          .eq('receiver_id', p.id)
          .eq('is_read', false)
          .count(CountOption.exact);
      if (mounted) {
        setState(() {
          _unreadNotifications = notifCount.count;
          _unreadMessages = msgCount.count;
        });
      }
    } catch (_) {}
  }

  void _openScreen(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => _fetchUnreadCounts());
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.primary,
              expandedHeight: 150,
              pinned: true,
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      onPressed: () =>
                          _openScreen(NotificationsScreen(profile: p)),
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        top: 10,
                        right: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'مرحبًا، ${p.fullName ?? 'الطالب'} 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              if (p.levelName != null) p.levelName,
                              if (p.sectionName != null) p.sectionName,
                            ].whereType<String>().join(' - '),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SectionTitle(title: 'وصول سريع'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.mail_outline_rounded,
                          label: 'الرسائل',
                          badge: _unreadMessages,
                          onTap: () =>
                              _openScreen(MessagesScreen(profile: p)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.photo_library_outlined,
                          label: 'المعرض',
                          onTap: () => _openScreen(const GalleryScreen()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.school_outlined,
                          label: 'البرامج',
                          onTap: () =>
                              _openScreen(ProgramsScreen(profile: p)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const SectionTitle(title: 'الإعلانات الأخيرة'),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_announcements.isEmpty)
                    const EmptyState(
                        icon: Icons.campaign_outlined,
                        message: 'لا توجد إعلانات حاليًا')
                  else
                    ..._announcements.map((a) => _AnnouncementCard(data: a)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;
  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    left: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnnouncementCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data['title'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ],
          ),
          if ((data['content'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              data['content'],
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
