class UserModel {
  final String id;
  final String name;
  final String mobileNumber;
  final String? address;            // only for customer
  final String role;                // customer/admin/salesman
  final String? assignedDistrict;   // only for salesman
  final String? workingRegion;      // only for salesman

  UserModel({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.address,
    required this.role,
    this.assignedDistrict,
    this.workingRegion,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      address: json['address'],
      role: json['role'] ?? '',
      assignedDistrict: json['assigned_district'],
      workingRegion: json['working_region'],
    );
  }

  // Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile_number': mobileNumber,
      'address': address,
      'role': role,
      'assigned_district': assignedDistrict,
      'working_region': workingRegion,
    };
  }
}
