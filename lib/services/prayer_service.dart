import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// FR-07: Prayer time retrieval via Aladhan REST API, with Firestore
/// caching to support offline access (PrayerCache collection).
class PrayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );
    } catch (_) {
      // Emulators often have no GPS fix ready. Fall back to the last known
      // position if one exists, rather than hanging indefinitely.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  /// Fetches today's prayer times for a given lat/lng using the
  /// public Aladhan API (method 3 = Muslim World League, matches
  /// the default 'MWL' calculation method from the Settings schema).
  Future<Map<String, String>> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    int method = 3,
  }) async {
    final today = DateTime.now();
    final cacheKey =
        '${today.year}-${today.month}-${today.day}_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';

    // 1. Try cache first (offline-friendly, NFR-REL-01 support).
    final cached = await _db.collection('PrayerCache').doc(cacheKey).get();
    if (cached.exists) {
      return Map<String, String>.from(cached.data()!['timings']);
    }

    // 2. Fetch live from Aladhan.
    final url = Uri.parse(
      'https://api.aladhan.com/v1/timings/${today.day}-${today.month}-${today.year}'
      '?latitude=$latitude&longitude=$longitude&method=$method',
    );
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prayer times (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final timingsRaw = data['data']['timings'] as Map<String, dynamic>;

    final timings = <String, String>{
      'Fajr': timingsRaw['Fajr'],
      'Dhuhr': timingsRaw['Dhuhr'],
      'Asr': timingsRaw['Asr'],
      'Maghrib': timingsRaw['Maghrib'],
      'Isha': timingsRaw['Isha'],
    };

    // 3. Cache the result.
    await _db.collection('PrayerCache').doc(cacheKey).set({
      'timings': timings,
      'fetchedAt': Timestamp.now(),
      'latitude': latitude,
      'longitude': longitude,
    });

    return timings;
  }
}