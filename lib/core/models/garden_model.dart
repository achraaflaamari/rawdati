class GardenModel {
  final String id;
  final String adminId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String workingHours;

  GardenModel({
    required this.id,
    required this.adminId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.workingHours,
  });

  factory GardenModel.fromJson(Map<String, dynamic> json) {
    return GardenModel(
      id: json['id'],
      adminId: json['admin_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      workingHours: json['working_hours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'working_hours': workingHours,
    };
  }
}
