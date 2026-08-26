import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/city.dart';
import '../../services/city_service.dart';
import '../../theme/deen_colors.dart';

/// Full-screen city search for the "enter a city" location option — pops
/// with the picked [City], or null if the user backs out. Search runs
/// entirely against the bundled `assets/cities.json` via [CityService], so
/// nothing is sent anywhere until a result is actually picked.
class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final _cityService = CityService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<City> _results = const [];
  bool _searching = false;
  bool _hasQuery = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = const [];
        _hasQuery = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _hasQuery = true;
    });
    final results = await _cityService.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DeenColors.surface(dark),
      appBar: AppBar(
        backgroundColor: DeenColors.surface(dark),
        elevation: 0,
        title: Text(l10n.chooseCityTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchCityHint,
                filled: true,
                fillColor: DeenColors.cardBackground(dark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: DeenColors.cardBorder(dark)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResults(l10n, dark)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n, bool dark) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (!_hasQuery) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.citySearchEmptyHint,
              style: TextStyle(fontSize: 13, color: DeenColors.textMuted(dark)),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.citySearchPrivacyNote,
              style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark), height: 1.5),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          l10n.citySearchNoResults,
          style: TextStyle(fontSize: 13, color: DeenColors.textMuted(dark)),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(height: 0.5, color: DeenColors.dividerLine(dark)),
      itemBuilder: (context, index) {
        final city = _results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.location_on_outlined, size: 20, color: DeenColors.primary),
          title: Text(city.name, style: TextStyle(fontSize: 14, color: DeenColors.primaryText(dark))),
          subtitle: Text(city.subtitle, style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark))),
          onTap: () => Navigator.pop(context, city),
        );
      },
    );
  }
}
