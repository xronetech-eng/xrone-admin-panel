import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _providedClient = client;

  final SupabaseClient? _providedClient;

  SupabaseClient? get _client {
    if (_providedClient != null) {
      return _providedClient;
    }

    try {
      final instance = Supabase.instance;
      return instance.isInitialized ? instance.client : null;
    } on Object catch (error) {
      _log('supabase unavailable', error);
      return null;
    }
  }

  Future<AdminAuthResult> restoreAdminSession() async {
    final client = _client;
    if (client == null) {
      return const AdminAuthResult.unauthenticated();
    }

    _logCurrentAuth(client, source: 'restore');

    final user = client.auth.currentUser;
    final session = client.auth.currentSession;
    if (user == null || session == null) {
      return const AdminAuthResult.unauthenticated();
    }

    final role = await _lookupAdminRole(client, user.id);
    if (role == null) {
      await signOut();
      return const AdminAuthResult.accessDenied();
    }

    final profile = await loadCurrentAdminProfile();
    return AdminAuthResult.authenticated(
      userId: user.id,
      email: profile.email,
      role: role,
      fullName: profile.fullName,
    );
  }

  Future<AdminAuthResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthRepositoryException('Supabase is not initialized.');
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _log(
        'signInWithPassword currentUser=${response.user?.id} '
        'currentSession=${response.session != null}',
      );
      _logCurrentAuth(client, source: 'signIn');

      final user = response.user ?? client.auth.currentUser;
      if (user == null) {
        throw const AuthRepositoryException(
          'Supabase login did not return a user.',
        );
      }

      final role = await _lookupAdminRole(client, user.id);
      if (role == null) {
        await signOut();
        return const AdminAuthResult.accessDenied();
      }

      final profile = await loadCurrentAdminProfile();
      return AdminAuthResult.authenticated(
        userId: user.id,
        email: profile.email,
        role: role,
        fullName: profile.fullName,
      );
    } on AuthException catch (error) {
      _log('auth failure', error);
      throw AuthRepositoryException(error.message);
    } on PostgrestException catch (error) {
      _log('policy/query failure during login', error);
      throw AuthRepositoryException(error.message);
    }
  }

  Future<void> sendPasswordResetLink({required String email}) async {
    final client = _client;
    if (client == null) {
      throw const AuthRepositoryException('Supabase is not initialized.');
    }

    try {
      await client.auth.resetPasswordForEmail(email);
      _log('resetPasswordForEmail sent email=$email');
    } on AuthException catch (error) {
      _log('reset password auth failure', error);
      throw AuthRepositoryException(_passwordResetMessage(error));
    } on Object catch (error) {
      _log('reset password failure', error);
      throw const AuthRepositoryException(
        'Unable to send password reset link.',
      );
    }
  }

  Future<AuthAdminProfile> loadCurrentAdminProfile() async {
    final client = _client;
    if (client == null) {
      throw const AuthRepositoryException('Supabase is not initialized.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthRepositoryException('No authenticated admin found.');
    }

    final adminRow = await _fetchAdminRow(client, user.id);
    final role = _rowText(adminRow, 'role');
    if (role != 'admin') {
      throw const AuthRepositoryException(
        'Access denied. This account is not an admin.',
      );
    }

    return _profileFromUser(user, adminRow: adminRow);
  }

  Future<AuthAdminProfile> updateCurrentAdminProfile({
    required String fullName,
    required String email,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthRepositoryException('Supabase is not initialized.');
    }

    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw const AuthRepositoryException('No authenticated admin found.');
    }

    final metadata = Map<String, dynamic>.from(
      currentUser.userMetadata ?? const <String, dynamic>{},
    );
    metadata['full_name'] = fullName;
    metadata['name'] = fullName;
    metadata['display_name'] = fullName;

    try {
      await client.auth.updateUser(
        UserAttributes(
          email: email == (currentUser.email ?? '') ? null : email,
          data: metadata,
        ),
      );
      return loadCurrentAdminProfile();
    } on AuthException catch (error) {
      _log('profile update auth failure', error);
      throw AuthRepositoryException(_profileUpdateMessage(error));
    } on Object catch (error) {
      _log('profile update failure', error);
      throw const AuthRepositoryException('Unable to update profile.');
    }
  }

  Future<void> updateCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthRepositoryException('Supabase is not initialized.');
    }

    final currentUser = client.auth.currentUser;
    final email = currentUser?.email;
    if (currentUser == null || email == null || email.isEmpty) {
      throw const AuthRepositoryException('No authenticated admin found.');
    }

    try {
      await client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      _log('password update auth failure', error);
      throw AuthRepositoryException(_passwordUpdateMessage(error));
    } on Object catch (error) {
      _log('password update failure', error);
      throw const AuthRepositoryException('Unable to update password.');
    }
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) {
      return;
    }

    try {
      await client.auth.signOut();
      _log('signed out');
    } on Object catch (error) {
      _log('signOut failure', error);
      throw const AuthRepositoryException('Unable to logout.');
    }
  }

  Future<Map<String, dynamic>?> _fetchAdminRow(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      _log('admin profile lookup user_id=$userId');
      final row = await client
          .from('admin_users')
          .select()
          .eq('user_id', userId)
          .eq('role', 'admin')
          .maybeSingle();

      _log('admin profile lookup result=$row');
      return row;
    } on PostgrestException catch (error) {
      _log('admin profile lookup policy/query failure', error);
      rethrow;
    } on Object catch (error) {
      _log('admin profile lookup failure', error);
      rethrow;
    }
  }

  Future<String?> _lookupAdminRole(SupabaseClient client, String userId) async {
    try {
      _log('admin lookup user_id=$userId');
      final row = await client
          .from('admin_users')
          .select('user_id, role')
          .eq('user_id', userId)
          .eq('role', 'admin')
          .maybeSingle();

      _log('admin lookup result=$row');
      final role = row?['role']?.toString();
      return role == 'admin' ? role : null;
    } on PostgrestException catch (error) {
      _log('admin lookup policy/query failure', error);
      rethrow;
    } on Object catch (error) {
      _log('admin lookup failure', error);
      rethrow;
    }
  }

  AuthAdminProfile _profileFromUser(
    User user, {
    required Map<String, dynamic>? adminRow,
  }) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email ?? _rowText(adminRow, 'email');
    final fullName = _firstText([
      metadata['full_name'],
      metadata['name'],
      metadata['display_name'],
      _rowText(adminRow, 'full_name'),
      _rowText(adminRow, 'name'),
      _rowText(adminRow, 'display_name'),
      email,
    ]);

    return AuthAdminProfile(
      userId: user.id,
      fullName: fullName,
      email: email,
      role: _rowText(adminRow, 'role', fallback: 'admin'),
      profileImage: _firstText([
        metadata['avatar_url'],
        metadata['profile_image'],
        _rowText(adminRow, 'profile_image'),
        _rowText(adminRow, 'avatar_url'),
      ]),
      createdDate: _formatDate(user.createdAt),
      lastSignInDate: _formatDate(
        user.lastSignInAt ?? _rowText(adminRow, 'last_sign_in_at'),
      ),
    );
  }

  String _rowText(
    Map<String, dynamic>? row,
    String key, {
    String fallback = '',
  }) {
    if (row == null) {
      return fallback;
    }

    final value = row[key];
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _firstText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  String _formatDate(Object? value) {
    if (value == null) {
      return '-';
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return value.toString();
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')} '
        '${months[local.month - 1]} '
        '${local.year}';
  }

  String _profileUpdateMessage(AuthException error) {
    final message = error.message.trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('already') ||
        normalized.contains('registered') ||
        normalized.contains('exists')) {
      return 'This email is already in use.';
    }

    if (normalized.contains('confirm') || normalized.contains('verify')) {
      return 'Check your email to verify this change.';
    }

    return message.isEmpty ? 'Unable to update profile.' : message;
  }

  String _passwordUpdateMessage(AuthException error) {
    final message = error.message.trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid credentials')) {
      return 'Current password is invalid.';
    }

    if (normalized.contains('weak') || normalized.contains('password')) {
      return message.isEmpty ? 'Enter a stronger password.' : message;
    }

    return message.isEmpty ? 'Unable to update password.' : message;
  }

  String _passwordResetMessage(AuthException error) {
    final message = error.message.trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('user not found') ||
        normalized.contains('not found')) {
      return 'No user found with this email.';
    }

    return message.isEmpty ? 'Unable to send password reset link.' : message;
  }

  void _logCurrentAuth(SupabaseClient client, {required String source}) {
    _log('$source currentUser=${client.auth.currentUser?.id}');
    _log('$source currentSession=${client.auth.currentSession != null}');
  }

  void _log(String message, [Object? error]) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[AdminAuth] $message${error == null ? '' : ' | error=$error'}');
  }
}

class AdminAuthResult {
  const AdminAuthResult._({
    required this.status,
    this.userId,
    this.email,
    this.role,
    this.fullName,
  });

  const AdminAuthResult.unauthenticated()
    : this._(status: AdminAuthStatus.unauthenticated);

  const AdminAuthResult.accessDenied()
    : this._(status: AdminAuthStatus.accessDenied);

  const AdminAuthResult.authenticated({
    required String userId,
    required String email,
    required String role,
    required String fullName,
  }) : this._(
         status: AdminAuthStatus.authenticated,
         userId: userId,
         email: email,
         role: role,
         fullName: fullName,
       );

  final AdminAuthStatus status;
  final String? userId;
  final String? email;
  final String? role;
  final String? fullName;
}

enum AdminAuthStatus { unauthenticated, authenticated, accessDenied }

class AuthAdminProfile {
  const AuthAdminProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.profileImage,
    required this.createdDate,
    required this.lastSignInDate,
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String profileImage;
  final String createdDate;
  final String lastSignInDate;
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
