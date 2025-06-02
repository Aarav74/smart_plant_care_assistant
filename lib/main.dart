// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(PlantCareApp());
}

class PlantCareApp extends StatelessWidget {
  const PlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plant Care Assistant',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
            .copyWith(
              secondary: Colors.lightGreen,
              surface: Colors.white,
              background: const Color(0xFFF8FBF8),
            ),
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const PlantDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ====================== Data Models ======================
class PlantData {
  final int soilMoisture;
  final int lightLevel;
  final double temperature;
  final double humidity;
  final String status;
  final String emotion;
  final bool isOnline;
  final int timestamp;
  final String plantName;
  final int waterLevel;
  final double ph;
  final String plantType;

  PlantData({
    required this.soilMoisture,
    required this.lightLevel,
    required this.temperature,
    required this.humidity,
    required this.status,
    required this.emotion,
    required this.isOnline,
    required this.timestamp,
    this.plantName = "My Plant",
    this.waterLevel = 0,
    this.ph = 7.0,
    this.plantType = "generic",
  });

  factory PlantData.fromJson(Map<String, dynamic> json) {
    return PlantData(
      soilMoisture: json['soilMoisture'] ?? 0,
      lightLevel: json['lightLevel'] ?? 0,
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Unknown',
      emotion: json['emotion'] ?? 'neutral',
      isOnline: json['isOnline'] ?? false,
      timestamp: json['timestamp'] ?? 0,
      plantName: json['plantName'] ?? "My Plant",
      waterLevel: json['waterLevel'] ?? 0,
      ph: (json['ph'] ?? 7.0).toDouble(),
      plantType: json['plantType'] ?? "generic",
    );
  }

  PlantData copyWith({
    int? soilMoisture,
    int? lightLevel,
    double? temperature,
    double? humidity,
    String? status,
    String? emotion,
    bool? isOnline,
    int? timestamp,
    String? plantName,
    int? waterLevel,
    double? ph,
    String? plantType,
  }) {
    return PlantData(
      soilMoisture: soilMoisture ?? this.soilMoisture,
      lightLevel: lightLevel ?? this.lightLevel,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      status: status ?? this.status,
      emotion: emotion ?? this.emotion,
      isOnline: isOnline ?? this.isOnline,
      timestamp: timestamp ?? this.timestamp,
      plantName: plantName ?? this.plantName,
      waterLevel: waterLevel ?? this.waterLevel,
      ph: ph ?? this.ph,
      plantType: plantType ?? this.plantType,
    );
  }
}

class NotificationData {
  final String title;
  final String message;
  final DateTime timestamp;
  final String type;
  final bool isRead;

  NotificationData({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

// ====================== Plant Care Model ======================
class PlantCareModel {
  // This class simulates a pretrained model that provides plant-specific recommendations
  // In a production app, this would be replaced with actual model inference
  
  static Map<String, Map<String, dynamic>> plantRequirements = {
    'generic': {
      'moisture': {'min': 1200, 'max': 3500},
      'light': {'min': 500, 'max': 3000},
      'temperature': {'min': 18, 'max': 28},
      'humidity': {'min': 40, 'max': 70},
      'ph': {'min': 6.0, 'max': 7.5},
    },
    'succulent': {
      'moisture': {'min': 1000, 'max': 2000},
      'light': {'min': 2000, 'max': 4000},
      'temperature': {'min': 18, 'max': 30},
      'humidity': {'min': 30, 'max': 50},
      'ph': {'min': 6.0, 'max': 7.0},
    },
    'fern': {
      'moisture': {'min': 2000, 'max': 3500},
      'light': {'min': 500, 'max': 2000},
      'temperature': {'min': 15, 'max': 25},
      'humidity': {'min': 60, 'max': 80},
      'ph': {'min': 5.0, 'max': 6.5},
    },
    'orchid': {
      'moisture': {'min': 1500, 'max': 2500},
      'light': {'min': 1000, 'max': 3000},
      'temperature': {'min': 18, 'max': 28},
      'humidity': {'min': 50, 'max': 70},
      'ph': {'min': 5.5, 'max': 6.5},
    },
  };

  static String getRecommendation(PlantData data) {
    final type = data.plantType;
    final requirements = plantRequirements[type] ?? plantRequirements['generic']!;
    
    // Check each parameter and provide recommendations
    if (data.soilMoisture < requirements['moisture']!['min']) {
      return 'Water your ${_getPlantTypeName(type)} soon! Soil moisture is low.';
    }
    if (data.soilMoisture > requirements['moisture']!['max']) {
      return 'Soil is too wet for ${_getPlantTypeName(type)}.';
    }
    if (data.lightLevel < requirements['light']!['min']) {
      return '${_getPlantTypeName(type)} needs more light!';
    }
    if (data.lightLevel > requirements['light']!['max']) {
      return 'Too much direct light for ${_getPlantTypeName(type)}.';
    }
    if (data.temperature < requirements['temperature']!['min']) {
      return 'Temperature is too low for ${_getPlantTypeName(type)}.';
    }
    if (data.temperature > requirements['temperature']!['max']) {
      return '${_getPlantTypeName(type)} is too hot!';
    }
    if (data.humidity < requirements['humidity']!['min']) {
      return '${_getPlantTypeName(type)} needs more humidity.';
    }
    if (data.humidity > requirements['humidity']!['max']) {
      return 'Humidity is too high for ${_getPlantTypeName(type)}.';
    }
    return '${_getPlantTypeName(type)} is happy with current conditions!';
  }

  static String getStatus(PlantData data) {
    final type = data.plantType;
    final requirements = plantRequirements[type] ?? plantRequirements['generic']!;
    
    // Count how many parameters are out of range
    int issues = 0;
    if (data.soilMoisture < requirements['moisture']!['min'] || 
        data.soilMoisture > requirements['moisture']!['max']) {
      issues++;
    }
    if (data.lightLevel < requirements['light']!['min'] || 
        data.lightLevel > requirements['light']!['max']) {
      issues++;
    }
    if (data.temperature < requirements['temperature']!['min'] || 
        data.temperature > requirements['temperature']!['max']) {
      issues++;
    }
    
    if (issues == 0) return 'Healthy ${_getPlantTypeName(type)}';
    if (issues == 1) return '${_getPlantTypeName(type)} needs attention';
    if (issues == 2) return '${_getPlantTypeName(type)} stressed';
    return '${_getPlantTypeName(type)} in poor condition';
  }

  static String _getPlantTypeName(String type) {
    return {
      'generic': 'plant',
      'succulent': 'succulent',
      'fern': 'fern',
      'orchid': 'orchid',
    }[type] ?? 'plant';
  }
}

// ====================== Plant Type Selector ======================
class PlantTypeSelector extends StatefulWidget {
  final String currentType;
  final Function(String) onTypeSelected;

  const PlantTypeSelector({
    super.key,
    required this.currentType,
    required this.onTypeSelected,
  });

  @override
  State<PlantTypeSelector> createState() => _PlantTypeSelectorState();
}

class _PlantTypeSelectorState extends State<PlantTypeSelector> {
  late String _selectedType;

  final Map<String, Map<String, dynamic>> plantTypes = {
    'generic': {'name': 'Generic Plant', 'icon': Icons.eco},
    'succulent': {
      'name': 'Succulent',
      'icon': Icons.energy_savings_leaf,
    },
    'fern': {
      'name': 'Fern',
      'icon': Icons.forest,
    },
    'orchid': {
      'name': 'Orchid',
      'icon': Icons.local_florist,
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Plant Type'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: plantTypes.length,
          itemBuilder: (context, index) {
            final type = plantTypes.keys.elementAt(index);
            return ListTile(
              leading: Icon(plantTypes[type]!['icon'] as IconData?),
              title: Text(plantTypes[type]!['name'] as String),
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              trailing: _selectedType == type
                  ? Icon(Icons.check, color: Colors.green)
                  : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onTypeSelected(_selectedType);
            Navigator.pop(context);
          },
          child: Text('Select'),
        ),
      ],
    );
  }
}

// ====================== Main Dashboard ======================
class PlantDashboard extends StatefulWidget {
  const PlantDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PlantDashboardState createState() => _PlantDashboardState();
}

class _PlantDashboardState extends State<PlantDashboard>
    with TickerProviderStateMixin {
  PlantData? currentData;
  bool isConnected = false;
  Timer? _timer;
  List<PlantData> dataHistory = [];
  List<NotificationData> notifications = [];
  String esp32Ip = "192.168.1.100";

  // Animation controllers
  late AnimationController _blinkController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Animations
  late Animation<double> _blinkAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI State
  bool _showAdvanced = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    startDataFetching();
    // Load initial plant type from storage if available
    _loadInitialPlantType();
  }

  void _loadInitialPlantType() {
    // In a real app, you would load this from shared preferences
    // For now, we'll just set a default
    currentData = PlantData(
      soilMoisture: 0,
      lightLevel: 0,
      temperature: 0,
      humidity: 0,
      status: 'Loading...',
      emotion: 'neutral',
      isOnline: false,
      timestamp: 0,
      plantType: 'generic',
    );
  }

  void initializeAnimations() {
    _blinkController = AnimationController(
      duration: Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void startDataFetching() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchPlantData();
    });
    fetchPlantData(); // Initial fetch
  }

  Future<void> fetchPlantData() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://$esp32Ip/api/plant-data'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newData = PlantData.fromJson(data).copyWith(
          plantType: currentData?.plantType ?? 'generic',
        );

        setState(() {
          currentData = newData;
          isConnected = true;

          // Add to history (keep last 50 entries)
          dataHistory.add(newData);
          if (dataHistory.length > 50) {
            dataHistory.removeAt(0);
          }

          // Check for alerts
          checkAndAddNotifications(newData);
        });
      } else {
        setState(() {
          isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }

  void checkAndAddNotifications(PlantData data) {
    List<NotificationData> newNotifications = [];

    // Get plant-specific requirements
    final requirements = PlantCareModel.plantRequirements[data.plantType] ?? 
        PlantCareModel.plantRequirements['generic']!;

    if (data.soilMoisture < requirements['moisture']!['min']) {
      newNotifications.add(
        NotificationData(
          title: "💧 Water Alert",
          message: "${data.plantName} needs watering! Soil moisture is low.",
          timestamp: DateTime.now(),
          type: "water",
        ),
      );
    }

    if (data.temperature > requirements['temperature']!['max']) {
      newNotifications.add(
        NotificationData(
          title: "🌡️ Temperature Alert",
          message:
              "It's getting hot! Temperature is ${data.temperature.toStringAsFixed(1)}°C",
          timestamp: DateTime.now(),
          type: "temperature",
        ),
      );
    }

    if (data.lightLevel < requirements['light']!['min']) {
      newNotifications.add(
        NotificationData(
          title: "☀️ Light Alert",
          message: "${data.plantName} needs more light!",
          timestamp: DateTime.now(),
          type: "light",
        ),
      );
    }

    if (newNotifications.isNotEmpty) {
      setState(() {
        notifications.addAll(newNotifications);
        if (notifications.length > 20) {
          notifications = notifications.sublist(notifications.length - 20);
        }
      });
    }
  }

  Color getStatusColor() {
    if (!isConnected || currentData == null) return Colors.grey;

    switch (currentData!.emotion) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.red;
      case 'sleepy':
        return Colors.indigo;
      case 'hot':
        return Colors.deepOrange;
      case 'thirsty':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showPlantTypeSelector() {
    showDialog(
      context: context,
      builder: (context) => PlantTypeSelector(
        currentType: currentData?.plantType ?? 'generic',
        onTypeSelected: (type) {
          setState(() {
            currentData = currentData?.copyWith(plantType: type);
          });
          // Here you would typically save the plant type to persistent storage
          // and possibly send it to your backend
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.green[600]?.withOpacity(0.95),
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco, size: 24, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Plant Care Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.green[400]!.withOpacity(0.9),
                      Colors.green[600]!.withOpacity(0.95),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: notifications.isNotEmpty
                              ? _pulseAnimation.value
                              : 1.0,
                          child: Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    onPressed: () => _showNotifications(),
                  ),
                  if (notifications.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifications.length}',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedBuilder(
                animation: _blinkAnimation,
                builder: (context, child) {
                  return Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.green[100]!.withOpacity(
                              _blinkAnimation.value,
                            )
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isConnected ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: isConnected ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          isConnected ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isConnected
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Plant Character Section
                      SizedBox(
                        height: 320,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: getStatusColor().withOpacity(
                                            0.3 * _pulseAnimation.value,
                                          ),
                                          blurRadius: 50,
                                          spreadRadius: 20,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Center(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _blinkAnimation,
                                  _bounceAnimation,
                                ]),
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      -_bounceAnimation.value,
                                    ),
                                    child: _buildPlantCharacter(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Plant Status Card
                      _buildStatusCard(),

                      SizedBox(height: 20),

                      // Tab Navigation
                      _buildTabNavigation(),

                      SizedBox(height: 16),

                      // Tab Content
                      _buildTabContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCharacter() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green[100],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getPlantIcon(),
              size: 80,
              color: getStatusColor(),
            ),
            SizedBox(height: 10),
            Text(
              currentData?.plantName ?? 'My Plant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            Text(
              _getPlantTypeName(currentData?.plantType ?? 'generic'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlantIcon() {
    switch (currentData?.plantType) {
      case 'succulent':
        return Icons.energy_savings_leaf;
      case 'fern':
        return Icons.forest;
      case 'orchid':
        return Icons.local_florist;
      default:
        return Icons.eco;
    }
  }

  String _getPlantTypeName(String type) {
    return {
      'generic': 'Generic Plant',
      'succulent': 'Succulent',
      'fern': 'Fern',
      'orchid': 'Orchid',
    }[type] ?? 'Plant';
  }

  Widget _buildStatusCard() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                getStatusColor().withOpacity(0.15),
                Colors.white,
                getStatusColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Text(
                      currentData?.plantName ?? 'My Plant',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: getStatusColor(),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 8),
              Text(
                PlantCareModel.getStatus(currentData ?? PlantData(
                  soilMoisture: 0,
                  lightLevel: 0,
                  temperature: 0,
                  humidity: 0,
                  status: 'Unknown',
                  emotion: 'neutral',
                  isOnline: false,
                  timestamp: 0,
                  plantType: 'generic',
                )),
                style: TextStyle(
                  fontSize: 18,
                  color: getStatusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                isConnected
                    ? 'Last updated: ${_getTimeAgo()}'
                    : 'Attempting to reconnect...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTabButton('Sensors', 0, Icons.sensors),
          _buildTabButton('History', 1, Icons.timeline),
          _buildTabButton('Settings', 2, Icons.settings),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.all(4),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green[600] : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildSensorsTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildSettingsTab();
      default:
        return _buildSensorsTab();
    }
  }

  Widget _buildSensorsTab() {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildSensorCard(
              title: 'Soil Moisture',
              value: currentData?.soilMoisture.toString() ?? '--',
              unit: '',
              icon: Icons.opacity,
              color: Colors.blue,
              isGood: _isMoistureGood(),
              progress: (currentData?.soilMoisture ?? 0) / 4095,
            ),
            _buildSensorCard(
              title: 'Light Level',
              value: currentData?.lightLevel.toString() ?? '--',
              unit: 'lux',
              icon: Icons.wb_sunny,
              color: Colors.orange,
              isGood: _isLightGood(),
              progress: math.min((currentData?.lightLevel ?? 0) / 4000, 1.0),
            ),
            _buildSensorCard(
              title: 'Temperature',
              value: currentData?.temperature.toStringAsFixed(1) ?? '--',
              unit: '°C',
              icon: Icons.thermostat,
              color: Colors.red,
              isGood: _isTemperatureGood(),
              progress: math.max(
                0,
                math.min((currentData?.temperature ?? 0) / 40, 1.0),
              ),
            ),
            _buildSensorCard(
              title: 'Humidity',
              value: currentData?.humidity.toStringAsFixed(0) ?? '--',
              unit: '%',
              icon: Icons.water_drop,
              color: Colors.teal,
              isGood: _isHumidityGood(),
              progress: (currentData?.humidity ?? 0) / 100,
            ),
          ],
        ),

        SizedBox(height: 20),

        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: Colors.green[600],
                ),
                SizedBox(width: 8),
                Text(
                  _showAdvanced ? 'Hide Advanced' : 'Show Advanced',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        AnimatedContainer(
          duration: Duration(milliseconds: 400),
          height: _showAdvanced ? 200 : 0,
          child: _showAdvanced ? _buildAdvancedSensors() : null,
        ),
      ],
    );
  }

  bool _isMoistureGood() {
    if (currentData == null) return false;
    final requirements = PlantCareModel.plantRequirements[currentData!.plantType] ?? 
        PlantCareModel.plantRequirements['generic']!;
    return currentData!.soilMoisture >= requirements['moisture']!['min'] &&
           currentData!.soilMoisture <= requirements['moisture']!['max'];
  }

  bool _isLightGood() {
    if (currentData == null) return false;
    final requirements = PlantCareModel.plantRequirements[currentData!.plantType] ?? 
        PlantCareModel.plantRequirements['generic']!;
    return currentData!.lightLevel >= requirements['light']!['min'] &&
           currentData!.lightLevel <= requirements['light']!['max'];
  }

  bool _isTemperatureGood() {
    if (currentData == null) return false;
    final requirements = PlantCareModel.plantRequirements[currentData!.plantType] ?? 
        PlantCareModel.plantRequirements['generic']!;
    return currentData!.temperature >= requirements['temperature']!['min'] &&
           currentData!.temperature <= requirements['temperature']!['max'];
  }

  bool _isHumidityGood() {
    if (currentData == null) return false;
    final requirements = PlantCareModel.plantRequirements[currentData!.plantType] ?? 
        PlantCareModel.plantRequirements['generic']!;
    return currentData!.humidity >= requirements['humidity']!['min'] &&
           currentData!.humidity <= requirements['humidity']!['max'];
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isGood,
    required double progress,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '$value$unit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                isGood ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              PlantCareModel.getRecommendation(currentData ?? PlantData(
                soilMoisture: 0,
                lightLevel: 0,
                temperature: 0,
                humidity: 0,
                status: 'Unknown',
                emotion: 'neutral',
                isOnline: false,
                timestamp: 0,
                plantType: 'generic',
              )),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSensors() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildSensorCard(
            title: 'Water Level',
            value: currentData?.waterLevel.toString() ?? '--',
            unit: '%',
            icon: Icons.local_drink,
            color: Colors.cyan,
            isGood: (currentData?.waterLevel ?? 0) >= 20,
            progress: (currentData?.waterLevel ?? 0) / 100,
          ),
          _buildSensorCard(
            title: 'Soil pH',
            value: currentData?.ph.toStringAsFixed(1) ?? '--',
            unit: 'pH',
            icon: Icons.science,
            color: Colors.purple,
            isGood: (currentData?.ph ?? 0) >= 6.0 && (currentData?.ph ?? 0) <= 7.5,
            progress: math.max(0, math.min((currentData?.ph ?? 0) / 14, 1.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SizedBox(
      height: 400,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sensor History (Last 24 readings)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: dataHistory.isEmpty
                    ? Center(
                        child: Text(
                          'No historical data available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: math.min(dataHistory.length, 10),
                        itemBuilder: (context, index) {
                          final data =
                              dataHistory[dataHistory.length - 1 - index];
                          return _buildHistoryItem(data, index == 0);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(PlantData data, bool isLatest) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLatest ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: isLatest ? Border.all(color: Colors.green[200]!) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: data.isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.temperature.toStringAsFixed(1)}°C • ${data.humidity.toStringAsFixed(0)}% • Moisture: ${data.soilMoisture}',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatTimestamp(data.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (isLatest)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Latest',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.green[600]),
                    SizedBox(width: 8),
                    Text(
                      'ESP32 Connection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'ESP32 IP Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.router),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: fetchPlantData,
                    ),
                  ),
                  controller: TextEditingController(text: esp32Ip),
                  onChanged: (value) => esp32Ip = value,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: fetchPlantData,
                        icon: Icon(Icons.network_check),
                        label: Text('Test Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.eco, color: Colors.green[600]),
                    SizedBox(width: 8),
                    Text(
                      'Plant Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.local_florist),
                  title: Text('Plant Type'),
                  subtitle: Text(
                    _getPlantTypeName(currentData?.plantType ?? 'generic'),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showPlantTypeSelector,
                ),
                _buildSettingsItem(
                  'Automatic Watering',
                  value: false,
                  onChanged: (value) {},
                ),
                _buildSettingsItem(
                  'Light Alerts',
                  value: true,
                  onChanged: (value) {},
                ),
                _buildSettingsItem(
                  'Temperature Alerts',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    String title, {
    bool value = false,
    Function(bool)? onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.green),
        ],
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return ListTile(
                          leading: Icon(
                            _getNotificationIcon(notification.type),
                          ),
                          title: Text(notification.title),
                          subtitle: Text(notification.message),
                          trailing: Text(
                            _formatTimestamp(
                              notification.timestamp.millisecondsSinceEpoch ~/
                                  1000,
                            ),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'water':
        return Icons.opacity;
      case 'temperature':
        return Icons.thermostat;
      case 'light':
        return Icons.wb_sunny;
      default:
        return Icons.notifications;
    }
  }

  String _getTimeAgo() {
    if (currentData == null) return 'Never';
    final now = DateTime.now();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      currentData!.timestamp * 1000,
    );
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}