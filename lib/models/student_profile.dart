class StudentProfile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final String status;

  // من جدول students
  final String? studentId;
  final String? sectionId;
  final String? sectionName;
  final String? levelId;
  final String? levelName;
  final String? schoolName;

  StudentProfile({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.status,
    this.studentId,
    this.sectionId,
    this.sectionName,
    this.levelId,
    this.levelName,
    this.schoolName,
  });

  factory StudentProfile.fromProfileRow(Map<String, dynamic> profile,
      [Map<String, dynamic>? studentRow]) {
    return StudentProfile(
      id: profile['id'] as String,
      email: profile['email'] as String?,
      fullName: profile['full_name'] as String?,
      phone: profile['phone'] as String?,
      role: profile['role'] as String? ?? 'student',
      avatarUrl: profile['avatar_url'] as String?,
      status: profile['status'] as String? ?? 'active',
      studentId: studentRow?['id'] as String?,
      sectionId: studentRow?['section_id'] as String?,
      sectionName: (studentRow?['sections'] is Map)
          ? (studentRow?['sections']['name'] as String?)
          : null,
      levelId: studentRow?['level_id'] as String?,
      levelName: (studentRow?['educational_levels'] is Map)
          ? (studentRow?['educational_levels']['name_ar'] as String?)
          : null,
      schoolName: studentRow?['school_name'] as String?,
    );
  }
}
