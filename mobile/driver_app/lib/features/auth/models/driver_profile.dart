class DriverProfile {
  final int id;
  final int userId;
  final String licenseNumber;
  final String verificationStatus;
  final double rating;
  final bool isAvailable;

  const DriverProfile({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    required this.verificationStatus,
    required this.rating,
    required this.isAvailable,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        licenseNumber: json['license_number'] as String,
        verificationStatus: json['verification_status'] as String,
        rating: (json['rating'] as num).toDouble(),
        isAvailable: json['is_available'] as bool,
      );

  bool get isPending => verificationStatus == 'pending';
  bool get isVerified => verificationStatus == 'verified';
  bool get isRejected => verificationStatus == 'rejected';
}
