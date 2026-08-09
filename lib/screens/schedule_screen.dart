import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/student_profile.dart';
import '../widgets/empty_state.dart';

class ScheduleScreen extends StatefulWidget {
  final StudentProfile profile;
  const ScheduleScreen({super.key, required this.profile});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _schedule = [];
  bool _loading = true;

  static const days = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت'
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final sectionId = widget.profile.sectionId;
      var query = _client
          .from('teacher_schedule')
          .select('id, day, start_time, end_time, subject:subjects(name_ar)');
      final data = sectionId != null
          ? await query.eq('section_id', sectionId)
          : await query;
      if (mounted) {
        setState(() {
          _schedule = List<Map<String, dynamic>>.from(data);
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
      appBar: AppBar(title: const Text('الجدول الدراسي')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _schedule.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                        icon: Icons.calendar_month_outlined,
                        message: 'لا يوجد جدول دراسي مضاف بعد')
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: days.map((day) {
                      final items = _schedule
                          .where((s) => s['day'] == day)
                          .toList()
                        ..sort((a, b) => (a['start_time'] ?? '')
                            .compareTo(b['start_time'] ?? ''));
                      if (items.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary)),
                            const SizedBox(height: 10),
                            ...items.map((s) {
                              final subject = (s['subject'] is Map)
                                  ? (s['subject']['name_ar'] as String?)
                                  : null;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(subject ?? 'حصة',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                    ),
                                    Text(
                                      '${s['start_time'] ?? ''} - ${s['end_time'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
