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

  // Statistics
  Future<Map<String, int>> getDashboardStats() async {
    final childrenCount = await _supabase.from('children').select('id');
    final staffCount = await _supabase
        .from('profiles')
        .select('id')
        .eq('role', UserRole.staff.name);
    final parentsCount = await _supabase
        .from('profiles')
        .select('id')
        .eq('role', UserRole.parent.name);

    return {
      'children': (childrenCount as List).length,
      'staff': (staffCount as List).length,
      'parents': (parentsCount as List).length,
    };
  }

  // Account management
  Future<List<UserProfile>> getAccountsByRole(UserRole role) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', role.name);
    return (response as List)
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }

  Future<void> updateAccount(UserProfile profile) async {
    await _supabase
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  Future<void> deleteAccount(String id) async {
    await _supabase.rpc('delete_user', params: {'user_id': id});
  }

  Future<void> linkParentToChildren(String parentId, List<String> childIds) async {
    // Delete existing links for this parent
    await _supabase.from('child_parents').delete().eq('parent_id', parentId);

    if (childIds.isNotEmpty) {
      final inserts = childIds
          .map((childId) => {'parent_id': parentId, 'child_id': childId})
          .toList();

      await _supabase.from('child_parents').insert(inserts);
    }
  }

  Future<List<String>> getParentChildIds(String parentId) async {
    final response = await _supabase
        .from('child_parents')
        .select('child_id')
        .eq('parent_id', parentId);
    
    return (response as List).map((json) => json['child_id'] as String).toList();
  }

  Future<void> toggleBlockAccount(String id, bool blocked) async {
    await _supabase.rpc(
      'toggle_user_block',
      params: {'user_id': id, 'blocked': blocked},
    );
  }
}
