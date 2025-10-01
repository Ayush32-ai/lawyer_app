import 'package:flutter/foundation.dart';
import '../models/lawyer.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final List<Lawyer> _savedLawyers = [];
  final List<Lawyer> _recentlyViewed = [];

  List<Lawyer> get savedLawyers => List.unmodifiable(_savedLawyers);
  List<Lawyer> get recentlyViewed => List.unmodifiable(_recentlyViewed);

  // Initialize with some mock data
  void initializeMockData() {
    if (_savedLawyers.isEmpty) {
      // Add some saved lawyers from the mock data
      final mockLawyers = Lawyer.getMockLawyers();
      _savedLawyers.addAll([
        mockLawyers[0], // Sarah Johnson
        mockLawyers[2], // Emily Davis
      ]);
    }

    if (_recentlyViewed.isEmpty) {
      // Add some recently viewed lawyers
      final mockLawyers = Lawyer.getMockLawyers();
      _recentlyViewed.addAll([
        mockLawyers[1], // Michael Brown
        mockLawyers[0], // Sarah Johnson
        mockLawyers[3], // David Wilson
      ]);
    }
    notifyListeners();
  }

  /// Check if a lawyer is saved/favorited
  bool isSaved(String lawyerId) {
    return _savedLawyers.any((lawyer) => lawyer.id == lawyerId);
  }

  /// Add a lawyer to saved/favorites
  void saveLawyer(Lawyer lawyer) {
    if (!isSaved(lawyer.id)) {
      _savedLawyers.insert(0, lawyer); // Add to beginning
      notifyListeners();
    }
  }

  /// Remove a lawyer from saved/favorites
  void unsaveLawyer(String lawyerId) {
    _savedLawyers.removeWhere((lawyer) => lawyer.id == lawyerId);
    notifyListeners();
  }

  /// Toggle save status for a lawyer
  void toggleSave(Lawyer lawyer) {
    if (isSaved(lawyer.id)) {
      unsaveLawyer(lawyer.id);
    } else {
      saveLawyer(lawyer);
    }
  }

  /// Add a lawyer to recently viewed (automatically called when viewing profile)
  void addToRecentlyViewed(Lawyer lawyer) {
    // Remove if already exists to avoid duplicates
    _recentlyViewed.removeWhere((l) => l.id == lawyer.id);

    // Add to beginning
    _recentlyViewed.insert(0, lawyer);

    // Keep only last 10 items
    if (_recentlyViewed.length > 10) {
      _recentlyViewed.removeRange(10, _recentlyViewed.length);
    }

    notifyListeners();
  }

  /// Clear all recently viewed lawyers
  void clearRecentlyViewed() {
    _recentlyViewed.clear();
    notifyListeners();
  }

  /// Clear all saved lawyers
  void clearSavedLawyers() {
    _savedLawyers.clear();
    notifyListeners();
  }

  /// Get saved lawyers by specialty
  List<Lawyer> getSavedBySpecialty(String specialty) {
    return _savedLawyers
        .where(
          (lawyer) => lawyer.specialty.toLowerCase() == specialty.toLowerCase(),
        )
        .toList();
  }

  /// Get recently viewed lawyers by specialty
  List<Lawyer> getRecentBySpecialty(String specialty) {
    return _recentlyViewed
        .where(
          (lawyer) => lawyer.specialty.toLowerCase() == specialty.toLowerCase(),
        )
        .toList();
  }
}







