import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/student_profile.dart';
import '../widgets/section_title.dart';
import '../widgets/empty_state.dart';

class DailyLessonsScreen extends StatefulWidget {
  final StudentProfile profile;
  const DailyLessonsScreen({super.key, required this.profile});

  @override
  State<DailyLessonsScreen> createState() => _DailyLessonsScreenState();
}

class _DailyLessonsScreenState extends State<DailyLessonsScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('daily_lessons')
          .select('id, title, achievements_ar, date, attachment_url, subject:subjects(name_ar)')
          .order('date', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() {
          _lessons = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الدروس اليومية')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _lessons.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                        icon: Icons.menu_book_outlined,
                        message: 'لا توجد دروس مضافة بعد')
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lessons.length,
                    itemBuilder: (context, i) {
                      final l = _lessons[i];
                      final subject = (l['subject'] is Map)
                          ? (l['subject']['name_ar'] as String?)
                          : null;
                      String dateStr = '';
                      try {
                        final d = DateTime.parse(l['date']);
                        dateStr = intl.DateFormat('d MMMM yyyy', 'ar').format(d);
                      } catch (_) {}
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
                                if (subject != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(subject,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                const Spacer(),
                                Text(dateStr,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(l['title'] ?? '',
                                style: const TextStyle(
                                    fontSize: 15.5, fontWeight: FontWeight.w700)),
                            if ((l['achievements_ar'] as String?)
                                    ?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 8),
                              Text(
                                l['achievements_ar'],
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.5),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
