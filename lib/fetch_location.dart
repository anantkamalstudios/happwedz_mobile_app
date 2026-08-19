import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationSelectionScreen extends StatefulWidget {
  @override
  _LocationSelectionScreenState createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  bool _showSearch = false;

  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final response = await http.get(
          Uri.parse('https://restcountries.com/v3.1/all?fields=name')
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> countries = data
            .map((country) => country['name']['common'] as String)
            .toList();
        countries.sort();

        setState(() {
          _countries = countries;
        });
      }
    } catch (e) {
      debugPrint('Error loading countries: $e');
    }
  }

  Future<void> _loadStates(String country) async {
    try {
      final response = await http.post(
        Uri.parse('https://countriesnow.space/api/v0.1/countries/states'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'country': country}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('States API Response: $data'); // Debug log

        if (data['error'] == false && data['data'] != null && data['data']['states'] != null) {
          final List<dynamic> statesData = data['data']['states'];
          final List<String> states = statesData
              .map((state) => state['name'] as String)
              .toList();
          states.sort();

          setState(() {
            _states = states;
            _selectedState = null;
            _selectedCity = null;
            _cities = [];
          });
        } else {
          // If no states found, add some fallback or show message
          setState(() {
            _states = ['No states available'];
            _selectedState = null;
            _selectedCity = null;
            _cities = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading states: $e');
      // Add fallback states
      setState(() {
        _states = ['Error loading states'];
      });
    }
  }

  Future<void> _loadCities(String country, String state) async {
    try {
      final response = await http.post(
        Uri.parse('https://countriesnow.space/api/v0.1/countries/state/cities'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'country': country,
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Cities API Response: $data'); // Debug log

        if (data['error'] == false && data['data'] != null) {
          final List<dynamic> citiesData = data['data'];
          final List<String> cities = citiesData
              .map((city) => city.toString())
              .toList();
          cities.sort();

          setState(() {
            _cities = cities;
            _selectedCity = null;
          });
        } else {
          setState(() {
            _cities = ['No cities available'];
            _selectedCity = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
      setState(() {
        _cities = ['Error loading cities'];
      });
    }
  }

  void _showLocationSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionBottomSheet(
        selectedCountry: _selectedCountry,
        selectedState: _selectedState,
        selectedCity: _selectedCity,
        countries: _countries,
        states: _states,
        cities: _cities,
        onCountrySelected: (country) {
          setState(() {
            _selectedCountry = country;
          });
          _loadStates(country);
        },
        onStateSelected: (state) {
          setState(() {
            _selectedState = state;
          });
          if (_selectedCountry != null) {
            _loadCities(_selectedCountry!, state);
          }
        },
        onCitySelected: (city) {
          setState(() {
            _selectedCity = city;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE91E63),
              Color(0xFFC2185B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  // Your main content here
                  child: Center(
                    child: Text(
                      'Main Content Area',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (_showSearch)
                Container(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Search...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              else
                Row(
                  children: [
                    Text(
                      _getLocationDisplayText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () {
                        _showLocationSelection(context);
                      },
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Right Section
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _showSearch ? Icons.close : Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  // Navigate to login
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocationDisplayText() {
    if (_selectedCity != null) {
      return _selectedCity!;
    } else if (_selectedState != null) {
      return _selectedState!;
    } else if (_selectedCountry != null) {
      return _selectedCountry!;
    }
    return "Select Location";
  }
}

class LocationSelectionBottomSheet extends StatefulWidget {
  final String? selectedCountry;
  final String? selectedState;
  final String? selectedCity;
  final List<String> countries;
  final List<String> states;
  final List<String> cities;
  final Function(String) onCountrySelected;
  final Function(String) onStateSelected;
  final Function(String) onCitySelected;

  const LocationSelectionBottomSheet({
    Key? key,
    this.selectedCountry,
    this.selectedState,
    this.selectedCity,
    required this.countries,
    required this.states,
    required this.cities,
    required this.onCountrySelected,
    required this.onStateSelected,
    required this.onCitySelected,
  }) : super(key: key);

  @override
  _LocationSelectionBottomSheetState createState() => _LocationSelectionBottomSheetState();
}

class _LocationSelectionBottomSheetState extends State<LocationSelectionBottomSheet> {
  String _currentView = 'country'; // 'country', 'state', 'city'
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.selectedCountry != null && widget.selectedState != null) {
      _currentView = 'city';
    } else if (widget.selectedCountry != null) {
      _currentView = 'state';
    }
  }

  List<String> _getFilteredItems() {
    List<String> items;
    switch (_currentView) {
      case 'country':
        items = widget.countries;
        break;
      case 'state':
        items = widget.states;
        break;
      case 'city':
        items = widget.cities;
        break;
      default:
        items = [];
    }

    if (_searchQuery.isEmpty) {
      return items;
    }

    return items
        .where((item) => item.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  String _getTitle() {
    switch (_currentView) {
      case 'country':
        return 'Select Country';
      case 'state':
        return 'Select State';
      case 'city':
        return 'Select City';
      default:
        return 'Select Location';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentView != 'country')
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (_currentView == 'city') {
                              _currentView = 'state';
                            } else if (_currentView == 'state') {
                              _currentView = 'country';
                            }
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _getTitle(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: const Icon(Icons.search, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Use Current Location (only for cities)
              if (_currentView == 'city')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      // Handle current location
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Row(
                        children: [
                          Icon(Icons.my_location, color: Colors.grey),
                          SizedBox(width: 12),
                          Text(
                            'Use Current Location',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: _currentView == 'country'
                        ? 'COUNTRIES/STATES'
                        : _currentView == 'state'
                        ? 'STATES'
                        : 'CITIES/STATES',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Section headers
              if (_currentView == 'country')
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TOP COUNTRIES',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (_currentView == 'city')
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TOP METROS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _getFilteredItems().length,
                  itemBuilder: (context, index) {
                    final item = _getFilteredItems()[index];
                    final isSelected = (_currentView == 'country' && item == widget.selectedCountry) ||
                        (_currentView == 'state' && item == widget.selectedState) ||
                        (_currentView == 'city' && item == widget.selectedCity);

                    return Container(
                      color: isSelected ? const Color(0xFFE91E63) : Colors.transparent,
                      child: ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          if (_currentView == 'country') {
                            widget.onCountrySelected(item);
                            setState(() {
                              _currentView = 'state';
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          } else if (_currentView == 'state') {
                            widget.onStateSelected(item);
                            setState(() {
                              _currentView = 'city';
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          } else {
                            widget.onCitySelected(item);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

