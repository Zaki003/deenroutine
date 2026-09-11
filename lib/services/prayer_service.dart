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

/// Aladhan's `method` param - which authority's angles compute Fajr/Isha.
/// [aladhanCode] is the exact numeric id Aladhan's API expects.
enum PrayerCalculationMethod {
  karachi(1),
  isna(2),
  mwl(3),
  ummAlQura(4);

  final int aladhanCode;
  const PrayerCalculationMethod(this.aladhanCode);

  static PrayerCalculationMethod fromCode(int? code) => PrayerCalculationMethod.values
      .firstWhere((m) => m.aladhanCode == code, orElse: () => PrayerCalculationMethod.mwl);
}

/// Aladhan's `school` param - the Asr shadow-length convention. Hanafi's
/// longer shadow requirement pushes Asr noticeably later than Standard
/// (Shafi'i/Maliki/Hanbali) - often by close to an hour.
enum AsrJuristicMethod {
  standard(0),
  hanafi(1);

  final int aladhanCode;
  const AsrJuristicMethod(this.aladhanCode);

  static AsrJuristicMethod fromCode(int? code) => AsrJuristicMethod.values
      .firstWhere((m) => m.aladhanCode == code, orElse: () => AsrJuristicMethod.standard);
}

/// FR-07: Prayer time retrieval via Aladhan REST API, with Firestore
/// caching to support offline access (PrayerCache collection).
class PrayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// [requestIfDenied] gates whether a currently-denied permission triggers
  /// Android's native request dialog. This must be `false` for any call the
  /// user didn't directly ask for (initial app launch, pull-to-refresh isn't
  /// exempt either, and definitely not an automatic retry on app resume) -
  /// Android permanently denies a permission after it's asked and refused
  /// twice, "don't ask again" checkbox or not, so a silent background call
  /// re-prompting on its own can burn through that budget before the user
  /// ever consciously chose to be asked again. Only a real, explicit user
  /// gesture for enabling location (onboarding's own prompt, or picking "use
  /// current location" from the location sheet) should pass `true`.
  Future<Position> getCurrentLocation({required bool requestIfDenied}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PrayerException(PrayerErrorType.locationServicesDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestIfDenied) {
        throw PrayerException(PrayerErrorType.permissionDenied);
      }
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

  /// Opens this app's system settings page — the only way out of
  /// [PrayerErrorType.permissionDeniedForever]. Once Android has permanently
  /// denied a permission, it won't show the in-app request dialog again
  /// (asking would silently no-op), regardless of how many times
  /// [getCurrentLocation] is retried.
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the device's location-services (GPS on/off) settings — separate
  /// from app permissions, and the only fix for
  /// [PrayerErrorType.locationServicesDisabled].
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

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

  /// Whether lat/lng falls inside a rough bounding box for Bangladesh,
  /// India, or Pakistan - approximate on purpose (a sensible starting
  /// default beats none; the user can always override it in Settings) and
  /// deliberately not precise at borders.
  bool _isSouthAsia(double lat, double lng) {
    bool inBox(double latMin, double latMax, double lngMin, double lngMax) =>
        lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax;
    return inBox(20.3, 26.7, 88.0, 92.7) || // Bangladesh
        inBox(6.5, 35.5, 68.0, 97.5) || // India
        inBox(23.5, 37.1, 60.9, 77.8); // Pakistan
  }

  /// Karachi is the conventional method across Bangladesh/India/Pakistan;
  /// MWL is the closest thing to a global/European default elsewhere.
  PrayerCalculationMethod defaultMethodFor({required double lat, required double lng}) =>
      _isSouthAsia(lat, lng) ? PrayerCalculationMethod.karachi : PrayerCalculationMethod.mwl;

  /// Hanafi is the common Asr convention across Bangladesh/India/Pakistan;
  /// Standard (Shafi'i/Maliki/Hanbali) elsewhere.
  AsrJuristicMethod defaultSchoolFor({required double lat, required double lng}) =>
      _isSouthAsia(lat, lng) ? AsrJuristicMethod.hanafi : AsrJuristicMethod.standard;

  /// Fetches today's prayer times for a given lat/lng using the public
  /// Aladhan API.
  Future<Map<String, String>> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    PrayerCalculationMethod method = PrayerCalculationMethod.mwl,
    AsrJuristicMethod school = AsrJuristicMethod.standard,
  }) async {
    final today = DateTime.now();
    // method/school are part of the key deliberately - without them, switching
    // either in Settings would keep serving the previous choice's cached
    // timings for the rest of the day instead of the newly picked one.
    final cacheKey = '${today.year}-${today.month}-${today.day}'
        '_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}'
        '_${method.aladhanCode}_${school.aladhanCode}';

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
      '?latitude=$latitude&longitude=$longitude&method=${method.aladhanCode}&school=${school.aladhanCode}',
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
      'method': method.aladhanCode,
      'school': school.aladhanCode,
    });

    return timings;
  }
}