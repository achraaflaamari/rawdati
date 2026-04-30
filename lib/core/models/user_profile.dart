enum UserRole { admin, staff, parent }

class UserProfile {
  final String id;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final String? address;
  final bool mustChangePassword;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.address,
    this.mustChangePassword = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      role: _parseRole(json['role']),
      fullName: json['full_name'],
      phone: json['phone'],
      address: json['address'],
      mustChangePassword: json['must_change_password'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'must_change_password': mustChangePassword,
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      case 'parent':
        return UserRole.parent;
      default:
        return UserRole.parent; // Default to parent if unknown
    }
  }
}
