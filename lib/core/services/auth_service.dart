import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required UserRole role,
    required String fullName,
    String? phone,
    String? address,
  }) async {
    // Try server-side creation first (does not replace admin session).
    try {
      final userId = await _supabase.rpc(
        'create_user_by_admin',
        params: {
          'p_email': email,
          'p_password': password,
          'p_role': role.name,
          'p_full_name': fullName,
          'p_phone': phone,
          'p_address': address,
        },
      );
      return userId as String?;
    } on PostgrestException catch (_) {
      // Fallback: use client-side signUp and restore the admin session after.
    }

    // Save current admin session so we can restore it after signUp.
    // signUp creates a session for the new user, which would replace the admin's.
    final previousSession = _supabase.auth.currentSession;

    // We pass metadata so the SQL trigger 'handle_new_user' creates the profile.
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': role.name,
        'full_name': fullName,
        'phone': phone,
        'address': address,
        'must_change_password': true,
      },
    );

    // Restore admin session so the admin stays logged in.
    if (previousSession != null && response.session != null) {
      try {
        await _supabase.auth.setSession(previousSession.refreshToken!);
      } catch (_) {
        // If restore fails, sign out so the admin can log in again.
        await _supabase.auth.signOut();
      }
    }

    return response.user?.id;
  }

  Future<void> updatePassword(String newPassword) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No user logged in');

    // Update password in Supabase Auth
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));

    // Update the must_change_password flag to false in profiles table
    // with proper error handling
    try {
      await _supabase
          .from('profiles')
          .update({'must_change_password': false})
          .eq('id', userId);
    } catch (e) {
      developer.log('Error updating must_change_password flag: $e');
      throw Exception('Failed to update password flag');
    }
  }

  Future<void> updateEmail(String newEmail) async {
    await _supabase.auth.updateUser(UserAttributes(email: newEmail));

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase
          .from('profiles')
          .update({'email': newEmail})
          .eq('id', userId);
    }
  }

  String generateRandomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    return List.generate(
      10,
      (index) => chars[Random().nextInt(chars.length)],
    ).join();
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
