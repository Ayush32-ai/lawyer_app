enum UserType {
  client,
  lawyer;

  String get displayName {
    switch (this) {
      case UserType.client:
        return 'Client';
      case UserType.lawyer:
        return 'Lawyer';
    }
  }

  String get description {
    switch (this) {
      case UserType.client:
        return 'Looking for legal help';
      case UserType.lawyer:
        return 'Providing legal services';
    }
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final UserType userType;
  final String? profileImage;
  final DateTime createdAt;

  // Client-specific fields
  final String? phoneNumber;
  final String? address;

  // Lawyer-specific fields
  final String? licenseNumber;
  final String? specialty;
  final int? yearsOfExperience;
  final double? rating;
  final String? bio;
  final List<String>? certifications;
  final bool? isVerified;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.profileImage,
    required this.createdAt,
    this.phoneNumber,
    this.address,
    this.licenseNumber,
    this.specialty,
    this.yearsOfExperience,
    this.rating,
    this.bio,
    this.certifications,
    this.isVerified,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserType? userType,
    String? profileImage,
    DateTime? createdAt,
    String? phoneNumber,
    String? address,
    String? licenseNumber,
    String? specialty,
    int? yearsOfExperience,
    double? rating,
    String? bio,
    List<String>? certifications,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      specialty: specialty ?? this.specialty,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      bio: bio ?? this.bio,
      certifications: certifications ?? this.certifications,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}





