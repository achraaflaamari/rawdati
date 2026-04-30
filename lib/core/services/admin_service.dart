import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/child_model.dart';
import '../models/user_profile.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Children management
  Future<List<ChildModel>> getChildren() async {
    final response = await _supabase.from('children').select();
    return (response as List).map((json) => ChildModel.fromJson(json)).toList();
  }

  Future<void> addChild(ChildModel child) async {
    await _supabase.from('children').insert(child.toJson());
  }

  Future<void> updateChild(ChildModel child) async {
    await _supabase.from('children').update(child.toJson()).eq('id', child.id);
  }

  Future<void> deleteChild(String id) async {
    await _supabase.from('children').delete().eq('id', id);
  }

  // Account management
  Future<List<UserProfile>> getAccountsByRole(UserRole role) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', role.name);
    return (response as List).map((json) => UserProfile.fromJson(json)).toList();
  }

  Future<void> deleteAccount(String id) async {
    // Note: This only deletes the profile, not the auth user.
    // In a real app, you'd use a service role or edge function to delete the auth user.
    await _supabase.from('profiles').delete().eq('id', id);
  }
}
