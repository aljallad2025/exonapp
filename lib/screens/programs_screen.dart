import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/student_profile.dart';
import '../widgets/empty_state.dart';

class ProgramsScreen extends StatefulWidget {
  final StudentProfile profile;
  const ProgramsScreen({super.key, required this.profile});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final studentId = widget.profile.studentId;
    if (studentId == null) {
      setState(() {
        _enrollments = [];
        _loading = false;
      });
      return;
    }
    try {
      final data = await _client
          .from('enrollments')
          .select(
              'id, status, progress, enrolled_at, program:programs(id, title, description, image_url, price, status)')
          .eq('student_id', studentId)
          .order('enrolled_at', ascending: false);
      if (mounted) {
        setState(() {
          _enrollments = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
      case 'in_progress':
        return AppColors.success;
      case 'completed':
        return AppColors.primary;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      default:
        return status ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('البرامج')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _enrollments.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                        icon: Icons.school_outlined,
                        message: 'لا توجد برامج مسجّل بها حاليًا')
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _enrollments.length,
                    itemBuilder: (context, i) {
                      final e = _enrollments[i];
                      final program = (e['program'] is Map)
                          ? e['program'] as Map<String, dynamic>
                          : <String, dynamic>{};
                      final progress =
                          ((e['progress'] as int?) ?? 0).clamp(0, 100);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((program['image_url'] as String?)
                                    ?.isNotEmpty ==
                                true)
                              CachedNetworkImage(
                                imageUrl: program['image_url'],
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                    height: 130, color: AppColors.border),
                                errorWidget: (_, __, ___) => Container(
                                    height: 130, color: AppColors.border),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                            program['title'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight:
                                                    FontWeight.w800)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(e['status'])
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _statusLabel(e['status']),
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  _statusColor(e['status'])),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((program['description'] as String?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      program['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          height: 1.5),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress / 100,
                                      minHeight: 8,
                                      backgroundColor: AppColors.border,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('$progress% مكتمل',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
