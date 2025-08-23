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
  });

  String get availabilityStatus => isAvailable ? 'Available Now' : 'Busy';

  /// Create Lawyer from Firestore data
  factory Lawyer.fromFirestore(Map<String, dynamic> data, String id) {
    return Lawyer(
      id: id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      distance: (data['distance'] ?? 0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      experienceYears: data['experienceYears'] ?? 0,
      bio: data['bio'] ?? '',
      consultationFee: (data['consultationFee'] ?? 0).toDouble(),
      profileImage: data['profileImage'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      specializations: List<String>.from(data['specializations'] ?? []),
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
        distance: 0.8,
        isAvailable: true,
        experienceYears: 12,
        bio:
            'Experienced criminal defense attorney with a proven track record of successful cases. Specializes in white-collar crimes and federal cases.',
        consultationFee: 250.0,
        profileImage: '',
        rating: 4.8,
        reviewCount: 156,
        phone: '+1 (555) 123-4567',
        email: 'sarah.johnson@lawfirm.com',
        specializations: [
          'Criminal Defense',
          'White Collar Crime',
          'Federal Cases',
        ],
      ),
      Lawyer(
        id: '2',
        name: 'Michael Chen',
        specialty: 'Family Law',
        distance: 1.2,
        isAvailable: false,
        experienceYears: 8,
        bio:
            'Compassionate family law attorney helping families navigate divorce, custody, and adoption proceedings with care and expertise.',
        consultationFee: 200.0,
        profileImage: '',
        rating: 4.7,
        reviewCount: 98,
        phone: '+1 (555) 234-5678',
        email: 'michael.chen@familylaw.com',
        specializations: [
          'Divorce',
          'Child Custody',
          'Adoption',
          'Domestic Relations',
        ],
      ),
      Lawyer(
        id: '3',
        name: 'Emily Rodriguez',
        specialty: 'Corporate Law',
        distance: 2.1,
        isAvailable: true,
        experienceYears: 15,
        bio:
            'Corporate law specialist with extensive experience in mergers, acquisitions, and business litigation. Trusted advisor to Fortune 500 companies.',
        consultationFee: 350.0,
        profileImage: '',
        rating: 4.9,
        reviewCount: 203,
        phone: '+1 (555) 345-6789',
        email: 'emily.rodriguez@corplaw.com',
        specializations: [
          'Corporate Law',
          'M&A',
          'Business Litigation',
          'Securities',
        ],
      ),
      Lawyer(
        id: '4',
        name: 'David Thompson',
        specialty: 'Personal Injury',
        distance: 0.5,
        isAvailable: true,
        experienceYears: 10,
        bio:
            'Personal injury attorney fighting for the rights of accident victims. No fee unless we win your case.',
        consultationFee: 0.0,
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
        name: 'Jennifer Williams',
        specialty: 'Immigration Law',
        distance: 1.8,
        isAvailable: false,
        experienceYears: 7,
        bio:
            'Immigration attorney helping individuals and families achieve their American dream through skilled legal representation.',
        consultationFee: 180.0,
        profileImage: '',
        rating: 4.8,
        reviewCount: 89,
        phone: '+1 (555) 567-8901',
        email: 'jennifer.williams@immigrationlaw.com',
        specializations: [
          'Immigration',
          'Visa Applications',
          'Green Cards',
          'Citizenship',
        ],
      ),
    ];
  }
}
