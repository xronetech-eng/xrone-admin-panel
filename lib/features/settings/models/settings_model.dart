class SettingsAdminProfile {
  const SettingsAdminProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.profileImage,
    required this.createdDate,
    required this.lastSignInDate,
  });

  static const empty = SettingsAdminProfile(
    userId: '',
    fullName: '',
    email: '',
    role: '',
    profileImage: '',
    createdDate: '-',
    lastSignInDate: '-',
  );

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String profileImage;
  final String createdDate;
  final String lastSignInDate;

  String get displayName => fullName.isEmpty ? email : fullName;
  String get displayRole => role.isEmpty ? 'Admin' : role;

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) {
      return '';
    }

    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      final end = parts.first.length < 2 ? parts.first.length : 2;
      return parts.first.substring(0, end).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
