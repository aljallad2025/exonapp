import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_profile.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  User? get currentUser => _client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  /// تسجيل الدخول — يطابق تمامًا منطق login/page.tsx في الموقع:
  /// 1) تسجيل الدخول بالإيميل/كلمة المرور
  /// 2) التحقق من status (pending / inactive / active)
  /// 3) التحقق أن الدور = student فقط (هذا تطبيق للطلاب حصرًا)
  Future<StudentProfile> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = res.user;
    if (user == null) {
      throw AuthException('فشل تسجيل الدخول. تحقق من البيانات المدخلة.');
    }

    // جلب بيانات البروفايل
    final profile = await _client
        .from('profiles')
        .select('id, email, full_name, phone, role, avatar_url, status')
        .eq('id', user.id)
        .single();

    final status = profile['status'] as String?;
    if (status == 'pending') {
      await _client.auth.signOut();
      throw AuthException('حسابك بانتظار موافقة الإدارة. يرجى الانتظار.');
    }
    if (status == 'inactive') {
      await _client.auth.signOut();
      throw AuthException('حسابك معطل من قبل الإدارة. يرجى التواصل مع الإدارة.');
    }

    final role = profile['role'] as String?;
    if (role != 'student') {
      await _client.auth.signOut();
      throw AuthException('هذا التطبيق مخصص للطلاب فقط.');
    }

    // جلب بيانات جدول students المرتبطة (الصف/الشعبة/المدرسة)
    Map<String, dynamic>? studentRow;
    try {
      studentRow = await _client
          .from('students')
          .select(
              'id, section_id, level_id, school_name, sections(name), educational_levels(name_ar)')
          .eq('profile_id', user.id)
          .maybeSingle();
    } catch (_) {
      studentRow = null;
    }

    return StudentProfile.fromProfileRow(profile, studentRow);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// جلب البروفايل الحالي (يُستخدم عند فتح التطبيق وفيه جلسة محفوظة)
  Future<StudentProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final profile = await _client
        .from('profiles')
        .select('id, email, full_name, phone, role, avatar_url, status')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) return null;

    if (profile['status'] == 'inactive' || profile['status'] == 'pending') {
      await signOut();
      return null;
    }

    Map<String, dynamic>? studentRow;
    try {
      studentRow = await _client
          .from('students')
          .select(
              'id, section_id, level_id, school_name, sections(name), educational_levels(name_ar)')
          .eq('profile_id', user.id)
          .maybeSingle();
    } catch (_) {
      studentRow = null;
    }

    return StudentProfile.fromProfileRow(profile, studentRow);
  }
}
