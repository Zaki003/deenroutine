import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/city.dart';

/// Loads the bundled `assets/cities.json` list and searches it in memory —
/// no network call, no Firestore read, so a city search never leaves the
/// device until a prayer-times fetch actually happens for the one picked.
class CityService {
  List<City>? _cities;

  Future<List<City>> _loadAll() async {
    final cached = _cities;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/cities.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final countryNames = Map<String, String>.from(decoded['countries'] as Map);
    final rows = decoded['cities'] as List<dynamic>;

    // Already population-sorted (biggest first) by build_cities_asset.js —
    // preserved here so a name-only filter below keeps that ranking without
    // needing to re-sort on every search.
    final cities = rows
        .map((row) => City.fromRow(row as List<dynamic>, countryNames))
        .toList(growable: false);
    _cities = cities;
    return cities;
  }

  /// Cities whose name starts with [query] (case-insensitive), biggest
  /// population first, capped at [limit] so the results list stays short.
  /// Returns nothing for a blank/whitespace-only query rather than the
  /// world's biggest cities, since that's not a useful "search result".
  Future<List<City>> search(String query, {int limit = 20}) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];

    final all = await _loadAll();
    final matches = <City>[];
    for (final city in all) {
      if (city.name.toLowerCase().startsWith(needle)) {
        matches.add(city);
        if (matches.length >= limit) break;
      }
    }
    return matches;
  }
}
