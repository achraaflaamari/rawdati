import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity.dart';

class ParentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ActivityPhoto>> getParentFeed() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase.rpc(
      'get_parent_feed',
      params: {'p_parent_id': userId},
    );

    // Get user's own reactions to highlight them
    final myReactions = await _supabase
        .from('reactions')
        .select('photo_id, reaction_type')
        .eq('parent_id', userId);

    final Map<String, String> myReactionsMap = {
      for (var r in myReactions) r['photo_id']: r['reaction_type'],
    };

    return (response as List).map((json) {
      final photoId = json['photo_id'];
      return ActivityPhoto.fromJson(json, myReaction: myReactionsMap[photoId]);
    }).toList();
  }

  Future<void> reactToPhoto(String photoId, String reactionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('reactions').upsert({
      'photo_id': photoId,
      'parent_id': userId,
      'reaction_type': reactionType,
    }, onConflict: 'photo_id, parent_id');
  }

  Future<void> removeReaction(String photoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('reactions')
        .delete()
        .eq('photo_id', photoId)
        .eq('parent_id', userId);
  }
}
