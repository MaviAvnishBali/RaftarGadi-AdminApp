import 'dart:convert';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage/storage.dart';

enum AdminSessionStatus { unknown, authenticated, unauthenticated }

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String? email;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role,
    if (email != null) 'email': email,
  };

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String? ?? 'adm_1',
    name: json['name'] as String? ?? 'Admin Operator',
    phone: json['phone'] as String? ?? '+919999999999',
    role: json['role'] as String? ?? 'ADMIN',
    email: json['email'] as String?,
  );
}

class AdminSessionState {
  const AdminSessionState({required this.status, this.user});

  const AdminSessionState.unknown()
      : status = AdminSessionStatus.unknown,
        user = null;

  final AdminSessionStatus status;
  final AdminUser? user;

  bool get isAuthenticated => status == AdminSessionStatus.authenticated;
}

class AdminSessionController extends Notifier<AdminSessionState> {
  static const _userKey = 'admin_session_user';
  static const _tokenKey = 'admin_session_token';

  KeyValueStore get _store => ref.read(cacheStoreProvider);

  @override
  AdminSessionState build() {
    final api = ref.read(apiClientProvider);
    api.setOnUnauthorized(() {
      signOut();
    });
    return const AdminSessionState.unknown();
  }

  Future<void> bootstrap() async {
    final rawUser = _store.read<String>(_userKey);
    final token = _store.read<String>(_tokenKey);

    if (token != null && token.isNotEmpty) {
      ref.read(apiClientProvider).setAuthToken(token);
    }

    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUser) as Map<String, dynamic>;
        state = AdminSessionState(
          status: AdminSessionStatus.authenticated,
          user: AdminUser.fromJson(decoded),
        );
        return;
      } catch (_) {
        // Fallback to unauthenticated if corrupted
      }
    }

    state = const AdminSessionState(status: AdminSessionStatus.unauthenticated);
  }

  Future<void> signIn(AdminUser user, {String? token}) async {
    await _store.write(_userKey, jsonEncode(user.toJson()));
    if (token != null && token.isNotEmpty) {
      await _store.write(_tokenKey, token);
      ref.read(apiClientProvider).setAuthToken(token);
    }
    state = AdminSessionState(
      status: AdminSessionStatus.authenticated,
      user: user,
    );
  }

  Future<void> signOut() async {
    await _store.delete(_userKey);
    await _store.delete(_tokenKey);
    ref.read(apiClientProvider).setAuthToken(null);
    state = const AdminSessionState(status: AdminSessionStatus.unauthenticated);
  }
}

final adminSessionControllerProvider =
    NotifierProvider<AdminSessionController, AdminSessionState>(
  AdminSessionController.new,
);
