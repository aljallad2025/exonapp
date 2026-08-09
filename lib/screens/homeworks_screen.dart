import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/student_profile.dart';
import '../widgets/empty_state.dart';

class HomeworksScreen extends StatefulWidget {
  final StudentProfile profile;
  const HomeworksScreen({super.key, required this.profile});

  @override
  State<HomeworksScreen> createState() => _HomeworksScreenState();
}

class _HomeworksScreenState extends State<HomeworksScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _homeworks = [];
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
          .from('homeworks')
          .select('id, title, description, due_date, file_url, subject:subjects(name_ar)')
          .order('due_date', ascending: true)
          .limit(50);
      if (mounted) {
        setState(() {
          _homeworks = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isOverdue(String? dueDate) {
    if (dueDate == null) return false;
    try {
      final d = DateTime.parse(dueDate);
      return d.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الواجبات المدرسية')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _homeworks.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                        icon: Icons.assignment_outlined,
                        message: 'لا توجد واجبات حاليًا')
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _homeworks.length,
                    itemBuilder: (context, i) {
                      final h = _homeworks[i];
                      final subject = (h['subject'] is Map)
                          ? (h['subject']['name_ar'] as String?)
                          : null;
                      final overdue = _isOverdue(h['due_date']);
                      String dueStr = '';
                      try {
                        final d = DateTime.parse(h['due_date']);
                        dueStr = intl.DateFormat('d MMMM yyyy', 'ar').format(d);
                      } catch (_) {}
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: overdue
                                  ? AppColors.danger.withOpacity(0.4)
                                  : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(h['title'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (overdue
                                            ? AppColors.danger
                                            : AppColors.success)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    overdue ? 'منتهي' : 'مفتوح',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: overdue
                                            ? AppColors.danger
                                            : AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (subject != null)
                                  Text('$subject  •  ',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
                                Text('تسليم: $dueStr',
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                            if ((h['description'] as String?)?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 10),
                              Text(
                                h['description'],
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
