class ChildModel {
  final String id;
  final String firstName;
  final String lastName;
  final String group;
  final DateTime birthDate;
  final String? photoUrl;
  final List<String> parentIds;

  ChildModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.group,
    required this.birthDate,
    this.photoUrl,
    required this.parentIds,
  });

  String get fullName => '$firstName $lastName';

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      group: json['group_name'],
      birthDate: DateTime.parse(json['birth_date']),
      photoUrl: json['photo_url'],
      parentIds: List<String>.from(json['parent_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'group_name': group,
      'birth_date': birthDate.toIso8601String(),
      'photo_url': photoUrl,
      'parent_ids': parentIds,
    };
  }
}
