class Lawyer {
  final String id;
  final String name;
  final String specialty;
  final double distance;
  final bool isAvailable;
  final int experienceYears;
  final String bio;
  final double consultationFee;
  final String profileImage;
  final double rating;
  final int reviewCount;
  final String phone;
  final String email;
  final List<String> specializations;
  final String address;
  final double latitude;
  final double longitude;

  Lawyer({
    required this.id,
    required this.name,
    required this.specialty,
    required this.distance,
    required this.isAvailable,
    required this.experienceYears,
    required this.bio,
    required this.consultationFee,
    required this.profileImage,
    required this.rating,
    required this.reviewCount,
    required this.phone,
    required this.email,
    required this.specializations,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  String get availabilityStatus => isAvailable ? 'Available Now' : 'Busy';

  /// Create Lawyer from Firestore data
  factory Lawyer.fromFirestore(Map<String, dynamic> data, String id) {
    return Lawyer(
      id: id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      distance: (data['distance'] ?? 2.5)
          .toDouble(), // Default distance if not set
      isAvailable: data['isAvailable'] ?? true,
      experienceYears:
          data['yearsOfExperience'] ?? data['experienceYears'] ?? 0,
      bio: data['bio'] ?? '',
      consultationFee: data['ratePerCase'] != null
          ? (data['ratePerCase'] as num).toDouble()
          : 0.0, // Get rate per case from Firestore
      profileImage: data['profileImage'] ?? '',
      rating: (data['rating'] ?? 4.5)
          .toDouble(), // Default rating for new lawyers
      reviewCount: data['reviewCount'] ?? 0,
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      email: data['email'] ?? '',
      specializations: List<String>.from(
        data['specializations'] ?? [data['specialty'] ?? ''],
      ),
    );
  }

  /// Convert Lawyer to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'specialty': specialty,
      'distance': distance,
      'isAvailable': isAvailable,
      'experienceYears': experienceYears,
      'bio': bio,
      'consultationFee': consultationFee,
      'profileImage': profileImage,
      'rating': rating,
      'reviewCount': reviewCount,
      'phone': phone,
      'email': email,
      'specializations': specializations,
    };
  }

  // Add location field for the lawyer's office location
  String get location => 'New York, NY'; // Default location for now

  // Mock data for demonstration
  static List<Lawyer> getMockLawyers() {
    return [
      Lawyer(
        id: '1',
        name: 'Dr. Sarah Johnson',
        specialty: 'Criminal Law',
        distance: 0.0, // Will be calculated
        address: 'Crystal Court, Civil Lines, Jaipur',
        latitude: 26.9124,
        longitude: 75.7873,
        isAvailable: true,
        experienceYears: 12,
        bio:
            'Experienced criminal defense attorney with a proven track record of successful cases. Specializes in white-collar crimes and federal cases.',
        consultationFee: 2500.0,
        profileImage: '',
        rating: 4.8,
        reviewCount: 156,
        phone: '+91 9876543210',
        email: 'sarah.johnson@lawfirm.com',
        specializations: [
          'Criminal Defense',
          'White Collar Crime',
          'Federal Cases',
        ],
      ),
      Lawyer(
        id: '2',
        name: 'Amit Sharma',
        specialty: 'Family Law',
        distance: 0.0, // Will be calculated
        address: 'Vaishali Nagar, Jaipur',
        latitude: 26.9115,
        longitude: 75.7439,
        isAvailable: true,
        experienceYears: 8,
        bio:
            'Compassionate family law attorney helping families navigate divorce, custody, and adoption proceedings with care and expertise.',
        consultationFee: 2000.0,
        profileImage: '',
        rating: 4.7,
        reviewCount: 98,
        phone: '+91 9876543211',
        email: 'amit.sharma@familylaw.com',
        specializations: [
          'Divorce',
          'Child Custody',
          'Adoption',
          'Domestic Relations',
        ],
      ),
      Lawyer(
        id: '3',
        name: 'Priya Verma',
        specialty: 'Corporate Law',
        distance: 0.0, // Will be calculated
        address: 'Malviya Nagar, Jaipur',
        latitude: 26.8535,
        longitude: 75.8123,
        isAvailable: true,
        experienceYears: 15,
        bio:
            'Corporate law specialist with extensive experience in mergers, acquisitions, and business litigation. Trusted advisor to major Indian companies.',
        consultationFee: 3500.0,
        profileImage: '',
        rating: 4.9,
        reviewCount: 203,
        phone: '+91 9876543212',
        email: 'priya.verma@corplaw.com',
        specializations: [
          'Corporate Law',
          'M&A',
          'Business Litigation',
          'Securities',
        ],
      ),
      Lawyer(
        id: '4',
        name: 'Rajesh Kumar',
        specialty: 'Personal Injury',
        distance: 0.0, // Will be calculated
        address: 'C-Scheme, Jaipur',
        latitude: 26.9057,
        longitude: 75.7892,
        isAvailable: true,
        experienceYears: 10,
        bio:
            'Personal injury attorney fighting for the rights of accident victims. No fee unless we win your case.',
        consultationFee: 1500.0,
        profileImage: '',
        rating: 4.6,
        reviewCount: 142,
        phone: '+1 (555) 456-7890',
        email: 'david.thompson@pilaw.com',
        specializations: [
          'Personal Injury',
          'Auto Accidents',
          'Slip & Fall',
          'Medical Malpractice',
        ],
      ),
      Lawyer(
        id: '5',
        name: 'Meera Agarwal',
        specialty: 'Immigration Law',
        distance: 0.0, // Will be calculated
        address: 'Raja Park, Jaipur',
        latitude: 26.8998,
        longitude: 75.8227,
        isAvailable: true,
        experienceYears: 7,
        bio:
            'Immigration law expert helping individuals and families with visa applications, foreign education, and work permits.',
        consultationFee: 1800.0,
        profileImage: '',
        rating: 4.8,
        reviewCount: 89,
        phone: '+91 9876543213',
        email: 'meera.agarwal@immigrationlaw.com',
        specializations: [
          'Immigration Law',
          'Student Visas',
          'Work Permits',
          'Foreign Education',
        ],
      ),
    ];
  }
}
