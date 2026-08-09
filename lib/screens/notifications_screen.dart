import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/student_profile.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  final StudentProfile profile;
  const NotificationsScreen({super.key, required this.profile});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final sectionId = widget.profile.sectionId;
      // إشعار يخص الطالب لو: موجّه له شخصيًا، أو لدوره (طالب)، أو لشعبته
      final orFilters = [
        'target_user_id.eq.${widget.profile.id}',
        'target_role.eq.student',
        if (sectionId != null) 'target_section_id.eq.$sectionId',
      ].join(',');

      final data = await _client
          .from('notifications')
          .select(
              'id, title, content, type, target_user_id, is_read, created_at')
          .or(orFilters)
          .order('created_at', ascending: false)
          .limit(60);
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['is_read'] == true) return;
    setState(() => item['is_read'] = true);
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', item['id']);
    } catch (_) {}
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'homework':
        return Icons.assignment_rounded;
      case 'lesson':
        return Icons.menu_book_rounded;
      case 'message':
        return Icons.mail_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الإشعارات')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                        icon: Icons.notifications_none_rounded,
                        message: 'لا توجد إشعارات حاليًا')
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      final isRead = n['is_read'] == true;
                      String timeStr = '';
                      try {
                        timeStr = timeago.format(
                            DateTime.parse(n['created_at']),
                            locale: 'ar');
                      } catch (_) {}
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _markRead(n),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.white
                                : AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? AppColors.border
                                  : AppColors.primary.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_iconFor(n['type'] as String?),
                                    color: AppColors.accent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(n['title'] ?? '',
                                        style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: isRead
                                                ? FontWeight.w600
                                                : FontWeight.w800)),
                                    if ((n['content'] as String?)
                                            ?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        n['content'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary,
                                            height: 1.5),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(timeStr,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 9,
                                  height: 9,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
