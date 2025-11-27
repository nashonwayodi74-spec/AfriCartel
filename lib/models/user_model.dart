class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String role; // 'buyer', 'vendor', 'admin'
  final double walletBalance;
  final int loyaltyPoints;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = 'buyer',
    this.walletBalance = 0.0,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      role: map['role'] ?? 'buyer',
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'role': role,
      'walletBalance': walletBalance,
      'loyaltyPoints': loyaltyPoints,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
