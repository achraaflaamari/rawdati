import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/garden_model.dart';

class GardenService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<GardenModel?> getGardenInfo() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('garden_info')
          .select()
          .eq('admin_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return GardenModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateGardenInfo(GardenModel garden) async {
    await _supabase.from('garden_info').upsert(garden.toJson());
  }
}
