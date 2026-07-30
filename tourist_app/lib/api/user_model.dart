class UserModel {
  final int id;
  final String username;
  final String phoneNumber;
  final String emergencyContact;
  final String digitalId;

  UserModel({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.emergencyContact,
    required this.digitalId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? 'N/A',
      phoneNumber: json['phone_number'] ?? '',
      emergencyContact: json['emergency_contact'] ?? '',
      digitalId: json['digital_id'] ?? json['id'].toString(),
    );
  }
}

