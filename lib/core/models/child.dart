class Child {
  final String id;
  final String firstName;
  final String lastName;
  final String? groupName;
  final DateTime? birthDate;
  final String? photoUrl;
  final List<String> parentIds;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.groupName,
    this.birthDate,
    this.photoUrl,
    this.parentIds = const [],
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      groupName: json['group_name'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      photoUrl: json['photo_url'],
      parentIds: List<String>.from(json['parent_ids'] ?? []),
    );
  }

  String get fullName => '$firstName $lastName';
}
