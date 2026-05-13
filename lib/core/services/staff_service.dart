import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity.dart';
import '../models/child.dart';

class StaffService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Activity>> getActivitiesByDate(DateTime date) async {
    final dateString = date.toIso8601String().split('T')[0];
    final response = await _supabase
        .from('activities')
        .select()
        .eq('activity_date', dateString)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Activity.fromJson(json)).toList();
  }

  Future<Activity> createActivity({
    required String title,
    String? description,
    String? category,
    DateTime? date,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('activities')
        .insert({
          'staff_id': userId,
          'title': title,
          'description': description,
          'category': category,
          'activity_date': (date ?? DateTime.now()).toIso8601String().split(
            'T',
          )[0],
        })
        .select()
        .single();

    return Activity.fromJson(response);
  }

  Future<String> uploadPhoto(File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final path = 'activities/$fileName';

    await _supabase.storage.from('photos').upload(path, file);
    return _supabase.storage.from('photos').getPublicUrl(path);
  }

  Future<void> addPhotosToActivity(
    String activityId,
    List<String> photoUrls,
  ) async {
    final inserts = photoUrls
        .map((url) => {'activity_id': activityId, 'photo_url': url})
        .toList();

    await _supabase.from('activity_photos').insert(inserts);
  }

  Future<List<ActivityPhoto>> getActivityPhotos(String activityId) async {
    final response = await _supabase
        .from('activity_photos')
        .select('*, photo_assignments(child_id)')
        .eq('activity_id', activityId);

    return (response as List).map((json) {
      final childIds = (json['photo_assignments'] as List)
          .map((a) => a['child_id'] as String)
          .toList();
      return ActivityPhoto.fromJson(json, assignedChildIds: childIds);
    }).toList();
  }

  Future<void> assignChildrenToPhoto(
    String photoId,
    List<String> childIds,
  ) async {
    // Delete existing assignments for this photo
    await _supabase.from('photo_assignments').delete().eq('photo_id', photoId);

    if (childIds.isNotEmpty) {
      final inserts = childIds
          .map((childId) => {'photo_id': photoId, 'child_id': childId})
          .toList();

      await _supabase.from('photo_assignments').insert(inserts);
    }
  }

  Future<List<Child>> getAllChildren() async {
    final response = await _supabase
        .from('children')
        .select()
        .order('first_name');
    return (response as List).map((json) => Child.fromJson(json)).toList();
  }

  Future<List<Activity>> getAllActivities() async {
    final response = await _supabase
        .from('activities')
        .select()
        .order('activity_date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Activity.fromJson(json)).toList();
  }

  Future<void> deleteActivityDate(DateTime date) async {
    final dateString = date.toIso8601String().split('T')[0];
    await _supabase
        .from('activities')
        .delete()
        .eq('activity_date', dateString)
        .eq('staff_id', _supabase.auth.currentUser!.id);
  }

  Future<void> deleteActivity(String activityId) async {
    await _supabase.from('activities').delete().eq('id', activityId);
  }

  Future<void> updateActivity(
    String activityId, {
    String? title,
    String? description,
    String? category,
  }) async {
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('activities').update(updates).eq('id', activityId);
  }

  Future<void> deletePhoto(String photoId, String photoUrl) async {
    // Delete from database
    await _supabase.from('activity_photos').delete().eq('id', photoId);

    // Delete from storage
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      // The URL format is usually .../storage/v1/object/public/photos/activities/filename
      // We need the path after 'photos/'
      final photosIndex = pathSegments.indexOf('photos');
      if (photosIndex != -1 && photosIndex < pathSegments.length - 1) {
        final storagePath = pathSegments.sublist(photosIndex + 1).join('/');
        await _supabase.storage.from('photos').remove([storagePath]);
      }
    } catch (e) {
      // Ignore storage deletion errors
    }
  }

  Future<List<Child>> getChildrenByPhoto(String photoId) async {
    final response = await _supabase
        .from('photo_assignments')
        .select('children(*)')
        .eq('photo_id', photoId);

    return (response as List)
        .map((json) => Child.fromJson(json['children']))
        .toList();
  }
}
