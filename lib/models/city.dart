/// A picker entry from the bundled `assets/cities.json` list — GeoNames
/// cities with population > 15,000, used by [CityService] so someone can
/// set their prayer-time location by typing a city instead of granting GPS.
class City {
  final String name;
  final String countryCode;
  final String countryName;

  /// State/region name (e.g. "Illinois"), or empty when GeoNames has none
  /// for this city's country.
  final String region;
  final double latitude;
  final double longitude;
  final int population;

  const City({
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.population,
  });

  /// Parses one `cities` row — `[name, countryCode, region, lat, lng,
  /// population]` — as written by `scripts/build_cities_asset.js`, resolving
  /// the country name via the asset's own `countries` lookup.
  factory City.fromRow(List<dynamic> row, Map<String, String> countryNames) {
    final countryCode = row[1] as String;
    return City(
      name: row[0] as String,
      countryCode: countryCode,
      countryName: countryNames[countryCode] ?? countryCode,
      region: row[2] as String,
      latitude: (row[3] as num).toDouble(),
      longitude: (row[4] as num).toDouble(),
      population: row[5] as int,
    );
  }

  /// The picker result row's subtitle: "Illinois, United States" when a
  /// region is known, otherwise just "Egypt".
  String get subtitle => region.isEmpty ? countryName : '$region, $countryName';

  /// Label saved as the user's chosen manual location and shown wherever the
  /// current location is displayed, e.g. "Cairo, Egypt".
  String get displayLabel => '$name, $countryName';
}
