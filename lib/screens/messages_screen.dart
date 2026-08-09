import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/student_profile.dart';
import '../widgets/empty_state.dart';

class MessagesScreen extends StatefulWidget {
  final StudentProfile profile;
  const MessagesScreen({super.key, required this.profile});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      // sender:profiles!sender_id(...) => تلميح Supabase لتحديد أي عمود FK نستخدم للربط
      // (messages فيها receiver_id كمان بيشير لـ profiles، فلازم التحديد)
      final data = await _client
          .from('messages')
          .select(
              'id, content, created_at, is_read, sender_id, receiver_id, sender:profiles!sender_id(full_name, avatar_url)')
          .eq('receiver_id', widget.profile.id)
          .order('created_at', ascending: false)
          .limit(60);
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openMessage(Map<String, dynamic> m) async {
    if (m['is_read'] != true) {
      setState(() => m['is_read'] = true);
      try {
        await _client
            .from('messages')
            .update({'is_read': true})
            .eq('id', m['id']);
      } catch (_) {}
    }
    if (!mounted) return;
    final sender =
        (m['sender'] is Map) ? (m['sender']['full_name'] as String?) : null;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sender ?? 'رسالة',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Text(m['content'] ?? '',
                  style: const TextStyle(fontSize: 14.5, height: 1.7)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الرسائل')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _messages.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                        icon: Icons.mail_outline_rounded,
                        message: 'لا توجد رسائل حاليًا')
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final unread = m['is_read'] != true;
                      final sender = (m['sender'] is Map)
                          ? (m['sender']['full_name'] as String?)
                          : null;
                      final avatarUrl = (m['sender'] is Map)
                          ? (m['sender']['avatar_url'] as String?)
                          : null;
                      String dateStr = '';
                      try {
                        dateStr = intl.DateFormat('d MMM', 'ar')
                            .format(DateTime.parse(m['created_at']));
                      } catch (_) {}
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openMessage(m),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: unread
                                ? AppColors.primary.withOpacity(0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: unread
                                  ? AppColors.primary.withOpacity(0.25)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.12),
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? const Icon(Icons.person_rounded,
                                        color: AppColors.primary, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(sender ?? 'الإدارة',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: unread
                                                ? FontWeight.w800
                                                : FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      m['content'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(dateStr,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
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
