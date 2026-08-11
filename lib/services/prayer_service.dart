import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Kinds of error [PrayerService] can raise. Kept as a type (rather than a
/// pre-formatted English `Exception` message) so the UI layer can localize
/// it — services/providers stay `BuildContext`/`AppLocalizations`-free.
enum PrayerErrorType {
  locationServicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  fetchFailed,
  unknown,
}

class PrayerException implements Exception {
  final PrayerErrorType type;
  final String? detail;
  PrayerException(this.type, [this.detail]);
}

/// FR-07: Prayer time retrieval via Aladhan REST API, with Firestore
/// caching to support offline access (PrayerCache collection).
class PrayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PrayerException(PrayerErrorType.locationServicesDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw PrayerException(PrayerErrorType.permissionDenied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw PrayerException(PrayerErrorType.permissionDeniedForever);
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings(),
      );
    } catch (_) {
      // Emulators often have no GPS fix ready. Fall back to the last known
      // position if one exists, rather than hanging indefinitely.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  /// On Android, `forceLocationManager` reads the OS's raw `LocationManager`
  /// GPS provider directly. Without it, Geolocator goes through Google Play
  /// Services' Fused Location Provider, whose per-app "last location" cache
  /// starts empty on a fresh app run — on an emulator with no continuous GPS
  /// feed, that leaves nothing for Fused to return before the time limit,
  /// even once a fix has been pushed to the emulator's GPS.
  LocationSettings _locationSettings() {
    const accuracy = LocationAccuracy.medium;
    const timeLimit = Duration(seconds: 12);
    if (kIsWeb) return const LocationSettings(accuracy: accuracy, timeLimit: timeLimit);
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
          forceLocationManager: true,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(accuracy: accuracy, timeLimit: timeLimit);
      default:
        return const LocationSettings(accuracy: accuracy, timeLimit: timeLimit);
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
      // Firestore doesn't preserve map field key order, so the cached
      // timings must be rebuilt in canonical order (matching the live-fetch
      // path below) for PrayerProvider's rotation logic to work correctly.
      final raw = Map<String, dynamic>.from(cached.data()!['timings']);
      return <String, String>{
        'Fajr': raw['Fajr'],
        'Dhuhr': raw['Dhuhr'],
        'Asr': raw['Asr'],
        'Maghrib': raw['Maghrib'],
        'Isha': raw['Isha'],
      };
    }

    // 2. Fetch live from Aladhan.
    final url = Uri.parse(
      'https://api.aladhan.com/v1/timings/${today.day}-${today.month}-${today.year}'
      '?latitude=$latitude&longitude=$longitude&method=$method',
    );
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw PrayerException(PrayerErrorType.fetchFailed, '${response.statusCode}');
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