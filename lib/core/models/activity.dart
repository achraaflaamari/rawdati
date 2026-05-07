class Activity {
  final String id;
  final String staffId;
  final String title;
  final String? description;
  final String? category;
  final DateTime activityDate;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.staffId,
    required this.title,
    this.description,
    this.category,
    required this.activityDate,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      staffId: json['staff_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      activityDate: DateTime.parse(json['activity_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'title': title,
      'description': description,
      'category': category,
      'activity_date': activityDate.toIso8601String(),
    };
  }
}

class ActivityPhoto {
  final String id;
  final String activityId;
  final String photoUrl;
  final String? activityTitle;
  final DateTime? activityDate;
  final List<String> assignedChildIds;
  final Map<String, int> reactions;
  final String? myReaction;

  ActivityPhoto({
    required this.id,
    required this.activityId,
    required this.photoUrl,
    this.activityTitle,
    this.activityDate,
    this.assignedChildIds = const [],
    this.reactions = const {},
    this.myReaction,
  });

  factory ActivityPhoto.fromJson(
    Map<String, dynamic> json, {
    List<String> assignedChildIds = const [],
    String? myReaction,
  }) {
    // Handle reactions from the RPC which might be a Map or JSON string
    Map<String, int> reactionsMap = {};
    if (json['reactions'] != null) {
      if (json['reactions'] is Map) {
        (json['reactions'] as Map).forEach((key, value) {
          reactionsMap[key.toString()] = int.tryParse(value.toString()) ?? 0;
        });
      }
    }

    return ActivityPhoto(
      id: json['photo_id'] ?? json['id'],
      activityId: json['activity_id'],
      photoUrl: json['photo_url'],
      activityTitle: json['activity_title'],
      activityDate: json['activity_date'] != null
          ? DateTime.parse(json['activity_date'])
          : null,
      assignedChildIds: assignedChildIds,
      reactions: reactionsMap,
      myReaction: myReaction,
    );
  }
}
