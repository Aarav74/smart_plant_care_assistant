// pubspec.yaml dependencies:
// ignore_for_file: deprecated_member_use

/*
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.5
  dart_jsonwebtoken: ^2.4.2
  flutter_animate: ^4.2.0
  charts_flutter: ^0.12.0
  shared_preferences: ^2.2.2
  fl_chart: ^0.68.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
*/

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

class AnimatedBackground extends StatelessWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[50]!,
                Colors.green[100]!.withOpacity(0.8),
                Colors.green[50]!,
              ],
            ),
          ),
        ),
        // Pattern overlay
        CustomPaint(painter: BackgroundPatternPainter(), child: Container()),
        // Content
        child,
      ],
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = 30.0;
    for (double i = 0.0; i < size.width; i += spacing) {
      for (double j = 0.0; j < size.height; j += spacing) {
        // Draw leaf patterns
        final path = Path();
        path.moveTo(i, j);
        path.quadraticBezierTo(
          i + spacing / 2,
          j - spacing / 4,
          i + spacing,
          j,
        );
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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

class PlantLogoIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PlantLogoIcon({super.key, this.size = 32.0, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: PlantLogoPainter(color: color)),
    );
  }
}

class PlantLogoPainter extends CustomPainter {
  final Color color;

  PlantLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw pot
    final potPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.8)
      ..lineTo(size.width * 0.7, size.height * 0.8)
      ..lineTo(size.width * 0.65, size.height)
      ..lineTo(size.width * 0.35, size.height)
      ..close();

    // Draw main leaf body (circular for cartoon style)
    final bodyPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.45),
          radius: size.width * 0.3,
        ),
      );

    // Draw decorative leaves
    final leftLeafPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.4,
        size.width * 0.3,
        size.height * 0.25,
      );

    final rightLeafPath = Path()
      ..moveTo(size.width * 0.65, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.4,
        size.width * 0.7,
        size.height * 0.25,
      );

    // Draw stem
    final stemPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.75)
      ..lineTo(size.width * 0.5, size.height * 0.8);

    // Fill paths
    paint.style = PaintingStyle.fill;

    // Fill pot
    paint.color = color.withOpacity(0.2);
    canvas.drawPath(potPath, paint);

    // Fill body
    paint.color = color.withOpacity(0.15);
    canvas.drawPath(bodyPath, paint);

    // Draw strokes
    paint.style = PaintingStyle.stroke;
    paint.color = color;
    canvas.drawPath(potPath, paint);
    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(leftLeafPath, paint);
    canvas.drawPath(rightLeafPath, paint);
    canvas.drawPath(stemPath, paint);

    // Draw face
    final faceCenter = Offset(size.width * 0.5, size.height * 0.45);
    final eyeRadius = size.width * 0.04;
    final smileRadius = size.width * 0.15;

    // Draw eyes
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(faceCenter.dx - eyeRadius * 2, faceCenter.dy - eyeRadius),
      eyeRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(faceCenter.dx + eyeRadius * 2, faceCenter.dy - eyeRadius),
      eyeRadius,
      paint,
    );

    // Draw smile
    paint.style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: faceCenter, radius: smileRadius),
      0.2, // Start angle in radians
      2.7, // Sweep angle in radians
      false,
      paint,
    );

    // Draw rosy cheeks
    paint.style = PaintingStyle.fill;
    paint.color = color.withOpacity(0.2);
    canvas.drawCircle(
      Offset(faceCenter.dx - smileRadius, faceCenter.dy + eyeRadius),
      eyeRadius * 1.2,
      paint,
    );
    canvas.drawCircle(
      Offset(faceCenter.dx + smileRadius, faceCenter.dy + eyeRadius),
      eyeRadius * 1.2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  String esp32Ip = "192.168.1.100";

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    startDataFetching();
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
        final newData = PlantData.fromJson(data);

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

    if (data.soilMoisture < 1200) {
      newNotifications.add(
        NotificationData(
          title: "💧 Water Alert",
          message: "${data.plantName} needs watering! Soil moisture is low.",
          timestamp: DateTime.now(),
          type: "water",
        ),
      );
    }

    if (data.temperature > 30) {
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

    if (data.lightLevel < 300) {
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
        // Keep only last 20 notifications
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                    const PlantLogoIcon(size: 24),
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
                // Notifications bell
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
                // Connection status
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
                              // Background glow effect
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
                              // Plant character
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
                                      child: EnhancedPlantCharacter(
                                        emotion:
                                            currentData?.emotion ?? 'neutral',
                                        isOnline: isConnected,
                                        blinkValue: _blinkAnimation.value,
                                        plantName:
                                            currentData?.plantName ??
                                            "My Plant",
                                      ),
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
      ),
    );
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
                currentData?.status ?? 'Checking...',
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
        // Main Sensor Grid
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            EnhancedSensorCard(
              title: 'Soil Moisture',
              value: currentData?.soilMoisture.toString() ?? '--',
              unit: '',
              icon: Icons.opacity,
              color: Colors.blue,
              isGood: (currentData?.soilMoisture ?? 0) >= 1500,
              progress: (currentData?.soilMoisture ?? 0) / 4095,
              recommendation: _getSoilMoistureRecommendation(),
            ),
            EnhancedSensorCard(
              title: 'Light Level',
              value: currentData?.lightLevel.toString() ?? '--',
              unit: 'lux',
              icon: Icons.wb_sunny,
              color: Colors.orange,
              isGood:
                  (currentData?.lightLevel ?? 0) >= 500 &&
                  (currentData?.lightLevel ?? 0) <= 3000,
              progress: math.min((currentData?.lightLevel ?? 0) / 4000, 1.0),
              recommendation: _getLightRecommendation(),
            ),
            EnhancedSensorCard(
              title: 'Temperature',
              value: currentData?.temperature.toStringAsFixed(1) ?? '--',
              unit: '°C',
              icon: Icons.thermostat,
              color: Colors.red,
              isGood:
                  (currentData?.temperature ?? 0) >= 18 &&
                  (currentData?.temperature ?? 0) <= 28,
              progress: math.max(
                0,
                math.min((currentData?.temperature ?? 0) / 40, 1.0),
              ),
              recommendation: _getTemperatureRecommendation(),
            ),
            EnhancedSensorCard(
              title: 'Humidity',
              value: currentData?.humidity.toStringAsFixed(0) ?? '--',
              unit: '%',
              icon: Icons.water_drop,
              color: Colors.teal,
              isGood:
                  (currentData?.humidity ?? 0) >= 40 &&
                  (currentData?.humidity ?? 0) <= 70,
              progress: (currentData?.humidity ?? 0) / 100,
              recommendation: _getHumidityRecommendation(),
            ),
          ],
        ),

        SizedBox(height: 20),

        // Advanced sensors toggle
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

        // Advanced sensors
        AnimatedContainer(
          duration: Duration(milliseconds: 400),
          height: _showAdvanced ? 200 : 0,
          child: _showAdvanced ? _buildAdvancedSensors() : null,
        ),
      ],
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
          EnhancedSensorCard(
            title: 'Water Level',
            value: currentData?.waterLevel.toString() ?? '--',
            unit: '%',
            icon: Icons.local_drink,
            color: Colors.cyan,
            isGood: (currentData?.waterLevel ?? 0) >= 20,
            progress: (currentData?.waterLevel ?? 0) / 100,
            recommendation: 'Refill reservoir when below 20%',
          ),
          EnhancedSensorCard(
            title: 'Soil pH',
            value: currentData?.ph.toStringAsFixed(1) ?? '--',
            unit: 'pH',
            icon: Icons.science,
            color: Colors.purple,
            isGood:
                (currentData?.ph ?? 0) >= 6.0 && (currentData?.ph ?? 0) <= 7.5,
            progress: math.max(0, math.min((currentData?.ph ?? 0) / 14, 1.0)),
            recommendation: 'Optimal pH range: 6.0-7.5',
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
        // Connection Settings
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

        // Plant Settings
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

  // Helper methods
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

  String _getSoilMoistureRecommendation() {
    if (currentData == null) return 'Checking soil moisture...';
    final moisture = currentData!.soilMoisture;
    if (moisture < 1200) {
      return 'Water your plant soon!';
    } else if (moisture < 2000) {
      return 'Soil moisture is getting low';
    } else if (moisture > 3500) {
      return 'Soil is too wet';
    }
    return 'Soil moisture is optimal';
  }

  String _getLightRecommendation() {
    if (currentData == null) return 'Checking light levels...';
    final light = currentData!.lightLevel;
    if (light < 300) {
      return 'Move to a brighter spot';
    } else if (light > 3000) {
      return 'Protect from direct sun';
    }
    return 'Light level is good';
  }

  String _getTemperatureRecommendation() {
    if (currentData == null) return 'Checking temperature...';
    final temp = currentData!.temperature;
    if (temp < 18) {
      return 'Too cold for optimal growth';
    } else if (temp > 28) {
      return 'Consider cooling measures';
    }
    return 'Temperature is ideal';
  }

  String _getHumidityRecommendation() {
    if (currentData == null) return 'Checking humidity...';
    final humidity = currentData!.humidity;
    if (humidity < 40) {
      return 'Increase humidity';
    } else if (humidity > 70) {
      return 'Reduce humidity';
    }
    return 'Humidity is perfect';
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
}

// Custom Widgets moved outside of _PlantDashboardState
class EnhancedPlantCharacter extends StatelessWidget {
  final String emotion;
  final bool isOnline;
  final double blinkValue;
  final String plantName;

  const EnhancedPlantCharacter({
    super.key,
    required this.emotion,
    required this.isOnline,
    required this.blinkValue,
    required this.plantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green[100],
      ),
      child: Center(
        child: Icon(_getEmotionIcon(), size: 100, color: _getEmotionColor()),
      ),
    );
  }

  IconData _getEmotionIcon() {
    switch (emotion) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'sleepy':
        return Icons.bedtime;
      case 'hot':
        return Icons.whatshot;
      case 'thirsty':
        return Icons.water_drop;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getEmotionColor() {
    switch (emotion) {
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
}

class EnhancedSensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isGood;
  final double progress;
  final String recommendation;

  const EnhancedSensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.isGood,
    required this.progress,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
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
              recommendation,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
