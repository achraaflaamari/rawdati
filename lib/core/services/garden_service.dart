import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/garden_model.dart';

class GardenService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<GardenModel?> getGardenInfo() async {
    try {
      final response = await _supabase.from('garden_info').select().single();
      return GardenModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateGardenInfo(GardenModel garden) async {
    await _supabase.from('garden_info').update(garden.toJson()).eq('id', garden.id);
  }
}
