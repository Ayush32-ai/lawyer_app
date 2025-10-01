import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/lawyer.dart';
import 'lawyer_profile_screen.dart';

class LawyerSearchScreen extends StatefulWidget {
  final String location;

  const LawyerSearchScreen({super.key, required this.location});

  @override
  State<LawyerSearchScreen> createState() => _LawyerSearchScreenState();
}

class _LawyerSearchScreenState extends State<LawyerSearchScreen> {
  List<Lawyer> lawyers = [];
  List<Lawyer> filteredLawyers = [];
  String selectedSpecialty = 'All';
  String selectedAvailability = 'All';
  bool isMapView = false;
  bool isLoading = true;

  final List<String> specialties = [
    'All',
    'Criminal Law',
    'Family Law',
    'Corporate Law',
    'Personal Injury',
    'Immigration Law',
    'Real Estate Law',
    'Tax Law',
    'Employment Law',
    'Intellectual Property',
  ];

  final List<String> availabilityOptions = ['All', 'Available Now', 'Busy'];

  String _formatDistance(double distance) {
    if (distance < 0) return 'Location N/A';
    if (distance == 0) return 'Same location';
    return '${distance.toString()} km away';
  }

  @override
  void initState() {
    super.initState();
    _loadLawyers();
  }

  Future<void> _loadLawyers() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      debugPrint('🔄 Loading lawyers...');

      // Get client's location coordinates
      final locations = await locationFromAddress(widget.location);
      if (locations.isEmpty) {
        throw Exception('Could not get coordinates for ${widget.location}');
      }

      final clientLocation = locations.first;
      debugPrint(
        '📍 Client location: ${clientLocation.latitude}, ${clientLocation.longitude}',
      );

      // Get lawyers from Firestore
      final lawyerDocs = await FirebaseFirestore.instance
          .collection('lawyers')
          .get();
      debugPrint('📚 Found ${lawyerDocs.docs.length} lawyers in database');

      // Process each lawyer
      final lawyersWithDistance = <Lawyer>[];

      for (final doc in lawyerDocs.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          debugPrint('\n📄 Raw lawyer data for ${doc.id}:');
          debugPrint(data.toString());

          // Check location data
          debugPrint('🗺️ Lawyer ${doc.id} location data:');
          debugPrint(
            '   latitude: ${data['latitude']} (${data['latitude']?.runtimeType})',
          );
          debugPrint(
            '   longitude: ${data['longitude']} (${data['longitude']?.runtimeType})',
          );

          // Check rate data
          debugPrint('💰 Lawyer ${doc.id} rate data:');
          debugPrint(
            '   ratePerCase: ${data['ratePerCase']} (${data['ratePerCase']?.runtimeType})',
          );

          // Calculate distance if coordinates exist and are valid numbers
          if (data['latitude'] != null &&
              data['longitude'] != null &&
              data['latitude'] is num &&
              data['longitude'] is num) {
            final lawyerLat = (data['latitude'] as num).toDouble();
            final lawyerLng = (data['longitude'] as num).toDouble();

            debugPrint('   Coordinates valid: $lawyerLat, $lawyerLng');

            final distanceInMeters = Geolocator.distanceBetween(
              clientLocation.latitude,
              clientLocation.longitude,
              lawyerLat,
              lawyerLng,
            );

            // Convert to km with one decimal place, if distance is less than 10m show as 0km
            final distance = distanceInMeters / 1000;
            data['distance'] = distance < 0.01
                ? 0.0
                : double.parse(distance.toStringAsFixed(1));
            debugPrint('   📏 Calculated distance: ${data['distance']} km');
          } else {
            debugPrint(
              '⚠️ Lawyer ${doc.id} has invalid or missing coordinates',
            );
            data['distance'] = -1; // Special value to indicate missing location
          }

          // Create lawyer object with distance
          final lawyer = Lawyer.fromFirestore(data, doc.id);
          debugPrint('📏 ${lawyer.name}: ${_formatDistance(lawyer.distance)}');
          lawyersWithDistance.add(lawyer);
        } catch (e, stack) {
          debugPrint('❌ Error processing lawyer ${doc.id}: $e');
          debugPrint(stack.toString());
        }
      }

      if (!mounted) return;

      // Sort by distance and update state
      setState(() {
        lawyers = lawyersWithDistance
          ..sort((a, b) => a.distance.compareTo(b.distance));
        filteredLawyers = lawyers;
        isLoading = false;
      });

      debugPrint('✅ Successfully loaded ${lawyers.length} lawyers');
    } catch (e, stack) {
      debugPrint('❌ Error loading lawyers: $e');
      debugPrint(stack.toString());

      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _filterLawyers() {
    setState(() {
      filteredLawyers = lawyers.where((lawyer) {
        bool matchesSpecialty =
            selectedSpecialty == 'All' || lawyer.specialty == selectedSpecialty;
        bool matchesAvailability =
            selectedAvailability == 'All' ||
            lawyer.availabilityStatus == selectedAvailability;
        return matchesSpecialty && matchesAvailability;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Filter Lawyers',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specialization',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSpecialty,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: specialties.map((String specialty) {
                      return DropdownMenuItem<String>(
                        value: specialty,
                        child: Text(specialty),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedSpecialty = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Availability',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedAvailability,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: availabilityOptions.map((String availability) {
                      return DropdownMenuItem<String>(
                        value: availability,
                        child: Text(availability),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedAvailability = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _filterLawyers();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Find Lawyers',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                isMapView = !isMapView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Location and filter summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${filteredLawyers.length} lawyers found',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: isMapView ? _buildMapView() : _buildListView()),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Map View',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interactive map with lawyer locations\nwould be implemented here',
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isMapView = false;
                });
              },
              child: const Text('Switch to List View'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading lawyers...'),
          ],
        ),
      );
    }

    if (filteredLawyers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              lawyers.isEmpty
                  ? 'No lawyers found'
                  : 'No lawyers match your filters',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lawyers.isEmpty
                  ? 'Be the first lawyer to join our platform!'
                  : 'Try adjusting your search criteria',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (lawyers.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadLawyers,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLawyers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredLawyers.length,
        itemBuilder: (context, index) {
          final lawyer = filteredLawyers[index];
          return _buildLawyerCard(lawyer);
        },
      ),
    );
  }

  Widget _buildLawyerCard(Lawyer lawyer) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LawyerProfileScreen(lawyer: lawyer),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile picture placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(Icons.person, size: 30, color: Colors.blue[600]),
                ),
                const SizedBox(width: 16),

                // Lawyer info
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer.name,
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lawyer.specialty,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${lawyer.rating} (${lawyer.reviewCount} reviews)',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Availability status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lawyer.isAvailable
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: lawyer.isAvailable
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                    ),
                  ),
                  child: Text(
                    lawyer.isAvailable ? 'Available' : 'Busy',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: lawyer.isAvailable
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Distance and consultation fee
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDistance(lawyer.distance) +
                              ' • ${lawyer.address}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        color: Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lawyer.consultationFee == 0
                              ? 'Rate not set'
                              : '₹${lawyer.consultationFee.toInt()} per case',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: lawyer.consultationFee > 0
                                ? Colors.green[700]
                                : Colors.grey[600],
                            fontWeight: lawyer.consultationFee > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LawyerProfileScreen(lawyer: lawyer),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person, size: 18),
                    label: const Text('View Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: lawyer.isAvailable
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LawyerProfileScreen(lawyer: lawyer),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
