import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/city.dart';
import '../../models/country.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_pagination_bar.dart';

class AdminCitiesCountriesScreen extends StatefulWidget {
  final AuthService authService;

  const AdminCitiesCountriesScreen({super.key, required this.authService});

  @override
  State<AdminCitiesCountriesScreen> createState() => _AdminCitiesCountriesScreenState();
}

class _AdminCitiesCountriesScreenState extends State<AdminCitiesCountriesScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  late TabController _tabController;

  static const int _pageSize = 10;

  final _countrySearchController = TextEditingController();
  String _countryQuery = '';
  int _countryPage = 0;
  int _countryTotal = 0;
  List<CountryModel> _countries = [];
  bool _countriesLoading = true;
  String? _countriesError;

  final _citySearchController = TextEditingController();
  String _cityQuery = '';
  int _cityPage = 0;
  int _cityTotal = 0;
  List<CityModel> _cities = [];
  bool _citiesLoading = true;
  String? _citiesError;

  /// Full lists for dropdowns, name lookup, and duplicate checks (same as before, via API).
  List<CountryModel> _allCountries = [];
  List<CityModel> _allCities = [];
  bool _lookupLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLookups();
    _loadCountries();
    _loadCities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countrySearchController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  /// Countries + cities for add-city dropdown, duplicate checks, and subtitle names.
  Future<void> _loadLookups() async {
    if (!mounted) return;
    setState(() {
      _lookupLoading = true;
    });
    try {
      final countries = _api.getAllCountries();
      final cities = _api.getAllCities();
      final r = await Future.wait([countries, cities]);
      if (!mounted) return;
      setState(() {
        _allCountries = r[0] as List<CountryModel>;
        _allCities = r[1] as List<CityModel>;
        _lookupLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _lookupLoading = false;
        });
      }
    }
  }

  Future<void> _loadCountries() async {
    setState(() {
      _countriesLoading = true;
      _countriesError = null;
    });
    try {
      final p = await _api.getCountriesPaged(
        page: _countryPage,
        pageSize: _pageSize,
        nameGte: _countryQuery.isEmpty ? null : _countryQuery,
      );
      if (!mounted) return;
      var total = p.count ?? 0;
      if (p.resultList.isEmpty && total > 0) {
        final maxPage = ((total - 1) / _pageSize).floor();
        if (_countryPage > maxPage) {
          setState(() => _countryPage = maxPage);
          await _loadCountries();
          return;
        }
      }
      if (mounted) {
        setState(() {
          _countries = p.resultList;
          _countryTotal = total;
          _countriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _countriesError = 'Failed to load: $e';
          _countriesLoading = false;
        });
      }
    }
  }

  void _applyCountryFilter() {
    setState(() {
      _countryQuery = _countrySearchController.text.trim();
      _countryPage = 0;
    });
    _loadCountries();
  }

  void _clearCountryFilter() {
    _countrySearchController.clear();
    setState(() {
      _countryQuery = '';
      _countryPage = 0;
    });
    _loadCountries();
  }

  Future<void> _loadCities() async {
    setState(() {
      _citiesLoading = true;
      _citiesError = null;
    });
    try {
      final p = await _api.getCitiesPaged(
        page: _cityPage,
        pageSize: _pageSize,
        nameGte: _cityQuery.isEmpty ? null : _cityQuery,
      );
      if (!mounted) return;
      var total = p.count ?? 0;
      if (p.resultList.isEmpty && total > 0) {
        final maxPage = ((total - 1) / _pageSize).floor();
        if (_cityPage > maxPage) {
          setState(() => _cityPage = maxPage);
          await _loadCities();
          return;
        }
      }
      if (mounted) {
        setState(() {
          _cities = p.resultList;
          _cityTotal = total;
          _citiesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _citiesError = 'Failed to load: $e';
          _citiesLoading = false;
        });
      }
    }
  }

  void _applyCityFilter() {
    setState(() {
      _cityQuery = _citySearchController.text.trim();
      _cityPage = 0;
    });
    _loadCities();
  }

  void _clearCityFilter() {
    _citySearchController.clear();
    setState(() {
      _cityQuery = '';
      _cityPage = 0;
    });
    _loadCities();
  }

  String _countryName(int countryId) {
    final match = _allCountries.where((c) => c.countryId == countryId);
    return match.isEmpty ? '—' : match.first.name;
  }

  /// Returns true if a city with the same name (case-insensitive) already exists in the given country.
  bool _cityExistsInCountry(int countryId, String name, {int? excludeCityId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _allCities.any((c) {
      if (c.countryId != countryId) return false;
      if (excludeCityId != null && c.cityId == excludeCityId) return false;
      return c.name.trim().toLowerCase() == normalized;
    });
  }

  Future<void> _showSuccessPopup(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 15))),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showValidationPopup(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid data'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppTheme.contentBackground,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppTheme.primaryBlue,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.flag_outlined), text: 'Countries'),
                Tab(icon: Icon(Icons.location_city_outlined), text: 'Cities'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCountriesTab(),
              _buildCitiesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountriesTab() {
    if (_countriesError != null && !_countriesLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_countriesError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _loadCountries, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      );
    }
    if (_countriesLoading && _countries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.public, color: AppTheme.primaryBlue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Countries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text('Add and manage countries used for routes and cities.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _addCountry,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add country'),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _countrySearchController,
                          decoration: const InputDecoration(
                            labelText: 'Filter by name (starts with)',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _countriesLoading ? null : _applyCountryFilter,
                        icon: const Icon(Icons.filter_list, size: 20),
                        label: const Text('Apply'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _countriesLoading
                            ? null
                            : () {
                                if (_countrySearchController.text.isEmpty && _countryQuery.isEmpty) {
                                  return;
                                }
                                _clearCountryFilter();
                              },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_countriesLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _countries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _countryQuery.isEmpty ? 'No countries yet' : 'No countries match this filter',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                        if (_countryQuery.isEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Use "Add country" above to create one.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ],
                    ),
                  ),
                )
              : Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _countries.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final c = _countries[index];
                        return ListTile(
                          leading: CircleAvatar(radius: 20, backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1), child: Icon(Icons.flag, size: 20, color: AppTheme.primaryBlue)),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: _countriesLoading ? null : () => _editCountry(c), tooltip: 'Edit'),
                              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700), onPressed: _countriesLoading ? null : () => _deleteCountry(c), tooltip: 'Delete'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
        if (!_countriesLoading)
          AdminPaginationBar(
            total: _countryTotal,
            currentPage: _countryPage,
            pageSize: _pageSize,
            itemsOnPage: _countries.length,
            loading: _countriesLoading,
            onPrevious: () {
              setState(() => _countryPage--);
              _loadCountries();
            },
            onNext: () {
              setState(() => _countryPage++);
              _loadCountries();
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCitiesTab() {
    if (_citiesError != null && !_citiesLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_citiesError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _loadCities, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      );
    }
    if (_citiesLoading && _cities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_city, color: AppTheme.primaryBlue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text(
                              _lookupLoading
                                  ? 'Loading…'
                                  : _allCountries.isEmpty
                                      ? 'Add a country first, then add cities.'
                                      : 'Add and manage cities for routes.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: (_lookupLoading || _allCountries.isEmpty) ? null : _addCity,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add city'),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _citySearchController,
                          decoration: const InputDecoration(
                            labelText: 'Filter by city name (starts with)',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _citiesLoading ? null : _applyCityFilter,
                        icon: const Icon(Icons.filter_list, size: 20),
                        label: const Text('Apply'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _citiesLoading
                            ? null
                            : () {
                                if (_citySearchController.text.isEmpty && _cityQuery.isEmpty) {
                                  return;
                                }
                                _clearCityFilter();
                              },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_citiesLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _cities.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_city_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _cityQuery.isEmpty ? 'No cities yet' : 'No cities match this filter',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                        if (_cityQuery.isEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _allCountries.isEmpty && !_lookupLoading ? 'Add a country in the Countries tab first.' : 'Use "Add city" above to create one.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _cities.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final city = _cities[index];
                        return ListTile(
                          leading: CircleAvatar(radius: 20, backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1), child: Icon(Icons.location_on, size: 20, color: AppTheme.primaryBlue)),
                          title: Text(city.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(_countryName(city.countryId), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: _citiesLoading ? null : () => _editCity(city), tooltip: 'Edit'),
                              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700), onPressed: _citiesLoading ? null : () => _deleteCity(city), tooltip: 'Delete'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
        if (!_citiesLoading)
          AdminPaginationBar(
            total: _cityTotal,
            currentPage: _cityPage,
            pageSize: _pageSize,
            itemsOnPage: _cities.length,
            loading: _citiesLoading,
            onPrevious: () {
              setState(() => _cityPage--);
              _loadCities();
            },
            onNext: () {
              setState(() => _cityPage++);
              _loadCities();
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _addCountry() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Country'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                await _showValidationPopup(
                  'Please enter a valid country name before saving.',
                );
                return;
              }
              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        await _api.insertCountry(name: nameCtrl.text.trim());
        if (mounted) {
          await _loadLookups();
          await _loadCountries();
          await _showSuccessPopup('Country added successfully.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
    nameCtrl.dispose();
  }

  Future<void> _editCountry(CountryModel c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Country'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                await _showValidationPopup(
                  'Please enter a valid country name before saving.',
                );
                return;
              }
              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        await _api.updateCountry(c.countryId, name: nameCtrl.text.trim());
        if (mounted) {
          await _loadLookups();
          await _loadCountries();
          await _loadCities();
          await _showSuccessPopup('Country updated successfully.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
    nameCtrl.dispose();
  }

  Future<void> _deleteCountry(CountryModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Country'),
        content: Text('Delete "${c.name}"? Cities in this country may be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.deleteCountry(c.countryId);
        if (mounted) {
          await _loadLookups();
          await _loadCountries();
          await _loadCities();
          await _showSuccessPopup('Country deleted successfully.');
        }
      } on ApiException catch (e) {
        if (mounted) {
          await _showCountryDeleteErrorDialog(countryName: c.name, e: e);
        }
      } catch (_) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cannot delete country'),
              content: const Text(
                'The country could not be deleted. Please check your connection and try again.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _addCity() async {
    if (_allCountries.isEmpty) return;
    final sortedCountries = List<CountryModel>.of(_allCountries)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final nameCtrl = TextEditingController();
    int? selectedCountryId = sortedCountries.first.countryId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add City'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use — controlled selection in StatefulBuilder
                  value: selectedCountryId,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  items: sortedCountries
                      .map((c) => DropdownMenuItem(value: c.countryId, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCountryId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'City name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || selectedCountryId == null) {
                  await _showValidationPopup(
                    'Please select a country and enter a valid city name before saving.',
                  );
                  return;
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty && selectedCountryId != null) {
      final name = nameCtrl.text.trim();
      if (_cityExistsInCountry(selectedCountryId!, name)) {
        if (mounted) {
          final countryName = _countryName(selectedCountryId!);
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Duplicate city'),
              content: Text(
                '"$name" already exists in $countryName. Each city name must be unique within a country.',
              ),
              actions: [
                FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            ),
          );
        }
        nameCtrl.dispose();
        return;
      }
      try {
        await _api.insertCity(countryId: selectedCountryId!, name: name);
        if (mounted) {
          await _loadLookups();
          await _loadCities();
          await _showSuccessPopup('City added successfully.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
    nameCtrl.dispose();
  }

  Future<void> _editCity(CityModel city) async {
    final nameCtrl = TextEditingController(text: city.name);
    final countryName = _countryName(city.countryId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit City'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Country', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(countryName, style: TextStyle(fontSize: 15, color: Colors.grey.shade800)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('A city cannot be moved to another country.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'City name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                await _showValidationPopup(
                  'Please enter a valid city name before saving.',
                );
                return;
              }
              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final name = nameCtrl.text.trim();
      if (_cityExistsInCountry(city.countryId, name, excludeCityId: city.cityId)) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Duplicate city'),
              content: Text(
                '"$name" already exists in $countryName. Each city name must be unique within a country.',
              ),
              actions: [
                FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            ),
          );
        }
        nameCtrl.dispose();
        return;
      }
      try {
        await _api.updateCity(city.cityId, countryId: city.countryId, name: name);
        if (mounted) {
          await _loadLookups();
          await _loadCities();
          await _showSuccessPopup('City updated successfully.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
    nameCtrl.dispose();
  }

  Future<void> _deleteCity(CityModel city) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete City'),
        content: Text('Delete "${city.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.deleteCity(city.cityId);
        if (mounted) {
          await _loadLookups();
          await _loadCities();
          await _showSuccessPopup('City deleted successfully.');
        }
      } on ApiException catch (e) {
        if (mounted) {
          await _showCityDeleteErrorDialog(cityName: city.name, e: e);
        }
      } catch (_) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cannot delete city'),
              content: const Text(
                'The city could not be deleted. Please check your connection and try again.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  /// Prefer [ApiException] body `errors.userError` (400 from API [UserException]).
  /// Falls back to friendly text when the server still returns 500/legacy errors.
  Future<void> _showCityDeleteErrorDialog({
    required String cityName,
    required ApiException e,
  }) async {
    final apiMessage = _userErrorMessageFromApiBody(e.body);
    final isLikelyInUse = e.statusCode == 500 ||
        e.statusCode == 409 ||
        e.body.toLowerCase().contains('route') ||
        e.body.toLowerCase().contains('constraint') ||
        e.body.toLowerCase().contains('reference') ||
        e.body.toLowerCase().contains('foreign');

    final String message;
    if (e.statusCode == 400 && apiMessage != null && apiMessage.isNotEmpty) {
      message = apiMessage;
    } else if (e.statusCode == 404) {
      message = 'This city no longer exists or was already removed.';
    } else if (isLikelyInUse) {
      message =
          '“$cityName” cannot be deleted because it is still in use. One or more yachts may use it as a location, '
          'or one or more routes may start or end there. Update those records (or choose another city) before deleting.';
    } else {
      message = 'The city could not be deleted. Please try again in a moment.';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot delete city'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Same pattern as [_showCityDeleteErrorDialog]: API returns 400 + `errors.userError` for [UserException].
  Future<void> _showCountryDeleteErrorDialog({
    required String countryName,
    required ApiException e,
  }) async {
    final apiMessage = _userErrorMessageFromApiBody(e.body);
    final isLikelyInUse = e.statusCode == 500 ||
        e.statusCode == 409 ||
        e.body.toLowerCase().contains('city') ||
        e.body.toLowerCase().contains('constraint') ||
        e.body.toLowerCase().contains('reference') ||
        e.body.toLowerCase().contains('foreign');

    final String message;
    if (e.statusCode == 400 && apiMessage != null && apiMessage.isNotEmpty) {
      message = apiMessage;
    } else if (e.statusCode == 404) {
      message = 'This country no longer exists or was already removed.';
    } else if (isLikelyInUse) {
      message =
          '“$countryName” cannot be deleted because it is still in use. One or more cities are associated with this country. '
          'Remove or reassign those cities to another country before deleting.';
    } else {
      message = 'The country could not be deleted. Please try again in a moment.';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot delete country'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String? _userErrorMessageFromApiBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final errors = decoded['errors'];
      if (errors is! Map<String, dynamic>) return null;
      final userError = errors['userError'];
      if (userError is List && userError.isNotEmpty) {
        final first = userError.first;
        if (first is String && first.isNotEmpty) return first;
      }
    } catch (_) {}
    return null;
  }
}
