import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/city.dart';
import '../../models/country.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

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
  List<CountryModel> _countries = [];
  List<CityModel> _cities = [];
  bool _countriesLoading = true;
  bool _citiesLoading = true;
  String? _countriesError;
  String? _citiesError;
  String _countrySearch = '';
  String _citySearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCountries();
    _loadCities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _countriesLoading = true;
      _countriesError = null;
    });
    try {
      final list = await _api.getCountries();
      if (mounted) {
        setState(() {
          _countries = list;
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

  Future<void> _loadCities() async {
    setState(() {
      _citiesLoading = true;
      _citiesError = null;
    });
    try {
      final list = await _api.getCities();
      if (mounted) {
        setState(() {
          _cities = list;
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

  String _countryName(int countryId) {
    try {
      return _countries.firstWhere((c) => c.countryId == countryId).name;
    } catch (_) {
      return '—';
    }
  }

  List<CountryModel> get _filteredCountries {
    final q = _countrySearch.trim().toLowerCase();
    if (q.isEmpty) return _countries;
    return _countries.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  List<CityModel> get _filteredCities {
    final q = _citySearch.trim().toLowerCase();
    if (q.isEmpty) return _cities;
    return _cities.where((c) {
      final country = _countryName(c.countryId).toLowerCase();
      return c.name.toLowerCase().contains(q) || country.contains(q);
    }).toList();
  }

  /// Returns true if a city with the same name (case-insensitive) already exists in the given country.
  bool _cityExistsInCountry(int countryId, String name, {int? excludeCityId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _cities.any((c) {
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
    if (_countriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_countriesError != null) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search countries',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _countrySearch = v),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _filteredCountries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No countries yet', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('Use "Add country" above to create one.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredCountries.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final c = _filteredCountries[index];
                        return ListTile(
                          leading: CircleAvatar(radius: 20, backgroundColor: AppTheme.primaryBlue.withOpacity(0.1), child: Icon(Icons.flag, size: 20, color: AppTheme.primaryBlue)),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editCountry(c), tooltip: 'Edit'),
                              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700), onPressed: () => _deleteCountry(c), tooltip: 'Delete'),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitiesTab() {
    if (_citiesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_citiesError != null) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                        Text(_countries.isEmpty ? 'Add a country first, then add cities.' : 'Add and manage cities for routes.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _countries.isEmpty ? null : _addCity,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add city'),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search cities or countries',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _citySearch = v),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _filteredCities.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_city_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No cities yet', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text(_countries.isEmpty ? 'Add a country in the Countries tab first.' : 'Use "Add city" above to create one.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredCities.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        return ListTile(
                          leading: CircleAvatar(radius: 20, backgroundColor: AppTheme.primaryBlue.withOpacity(0.1), child: Icon(Icons.location_on, size: 20, color: AppTheme.primaryBlue)),
                          title: Text(city.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(_countryName(city.countryId), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editCity(city), tooltip: 'Edit'),
                              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700), onPressed: () => _deleteCity(city), tooltip: 'Delete'),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
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
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
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
          await _showSuccessPopup('Country added successfully.');
          _loadCountries();
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
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
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
          await _showSuccessPopup('Country updated successfully.');
          _loadCountries();
          _loadCities();
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
          await _showSuccessPopup('Country deleted successfully.');
          _loadCountries();
          _loadCities();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _addCity() async {
    if (_countries.isEmpty) return;
    final nameCtrl = TextEditingController();
    int? selectedCountryId = _countries.first.countryId;
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
                  value: selectedCountryId,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  items: _countries
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
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty && selectedCountryId != null) {
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
          await _showSuccessPopup('City added successfully.');
          _loadCities();
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
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
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
          await _showSuccessPopup('City updated successfully.');
          _loadCities();
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
          await _showSuccessPopup('City deleted successfully.');
          _loadCities();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
