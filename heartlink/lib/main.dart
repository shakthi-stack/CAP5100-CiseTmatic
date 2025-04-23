import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'services/ble_manager.dart'; // BLE manager located in lib/services/

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeartLink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'HeartLink'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// The main state holds the bottom navigation state and shows one of three pages.
class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 1; // default to Connect page

  // Create the three pages.
  final List<Widget> _pages = const [
    HomeScreen(),
    ConnectScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.connect_without_contact),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// ------------------ Home Screen ------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  // Sample recent session details.
  final List<String> sessions = const [
    "Session 1: 10/10/2022 - Avg 75 bpm",
    "Session 2: 10/11/2022 - Avg 78 bpm",
    "Session 3: 10/12/2022 - Avg 80 bpm",
  ];
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Large green "Start a New Session" button.
          ElevatedButton(
            onPressed: () {
              // Add your "start session" logic here.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              textStyle: const TextStyle(fontSize: 24),
            ),
            child: const Text("Start a New Session"),
          ),
          const SizedBox(height: 20),
          // Recent sessions list in a ListView.
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(sessions[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------ Connect Screen ------------------
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);
  
  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  int _heartRateA = 60;
  int _heartRateB = 60;
  Timer? _simulationTimer;
  
  // BLE managers for each person (for later integration)
  final BleManager _bleManagerA = BleManager();
  final BleManager _bleManagerB = BleManager();
  
  @override
  void initState() {
    super.initState();
    // Simulate heart rate data for both persons (range 60 to 200).
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _heartRateA = 60 + Random().nextInt(141); // 60 to 200
        _heartRateB = 60 + Random().nextInt(141);
      });
    });
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    _bleManagerA.disconnect();
    _bleManagerB.disconnect();
    super.dispose();
  }
  
  // Helper function to determine zone based on heart rate.
  int getZone(int heartRate) {
    if (heartRate <= 120) return 1;
    if (heartRate <= 140) return 2;
    if (heartRate <= 160) return 3;
    if (heartRate <= 180) return 4;
    return 5;
  }
  
  @override
  Widget build(BuildContext context) {
    bool zonesDiffer = getZone(_heartRateA) != getZone(_heartRateB);
    
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: buildHalf(
                backgroundColor: Colors.grey[100]!,
                personLabel: 'Person A',
                heartRate: _heartRateA,
              ),
            ),
            const Divider(
              color: Colors.black,
              height: 1,
              thickness: 5,
            ),
            Expanded(
              child: buildHalf(
                backgroundColor: Colors.grey[100]!,
                personLabel: 'Person B',
                heartRate: _heartRateB,
              ),
            ),
          ],
        ),
        // Overlay alert if the two persons are in different zones.
        if (zonesDiffer)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Text(
                "Alert: The two people are in different zones.\nPlease adjust your paces.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // Builds each half (upper and lower) with the pulsing heart and heart rate meter.
  Widget buildHalf({
    required Color backgroundColor,
    required String personLabel,
    required int heartRate,
  }) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Row with pulsing heart and heart rate meter.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PulseHeart(size: 100, color: Colors.red),
                const SizedBox(width: 20),
                HeartRateMeter(heartRate: heartRate),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              personLabel,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Heart Rate: $heartRate bpm',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------ Profile Screen ------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Profile Page", style: TextStyle(fontSize: 24)),
    );
  }
}

/// ------------------ PulseHeart Widget ------------------
class PulseHeart extends StatefulWidget {
  final double size;
  final Color color;
  const PulseHeart({Key? key, required this.size, required this.color}) : super(key: key);
  
  @override
  _PulseHeartState createState() => _PulseHeartState();
}

class _PulseHeartState extends State<PulseHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(
        Icons.favorite,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

/// ------------------ HeartRateMeter Widget ------------------
class HeartRateMeter extends StatelessWidget {
  final int heartRate; // Expected range: 0 to 200
  // Fixed dimensions for the meter bar.
  final double barHeight;
  final double barWidth;
  
  const HeartRateMeter({
    Key? key,
    required this.heartRate,
    this.barHeight = 200,
    this.barWidth = 50,
  }) : super(key: key);
  
  // Returns the fill color based on the heart rate.
  Color _getFillColor() {
    if (heartRate <= 120) return Colors.blue;
    if (heartRate <= 140) return Colors.green;
    if (heartRate <= 160) return Colors.yellow;
    if (heartRate <= 180) return Colors.orange;
    return Colors.red;
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate fill height as a proportion of the bar.
    double fillHeight = (heartRate.clamp(0, 200) / 200) * barHeight;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // The meter bar with an animated fill.
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: barHeight,
              width: barWidth,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: Colors.grey[300],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: fillHeight,
              width: barWidth,
              color: _getFillColor(),
            ),
          ],
        ),
        const SizedBox(width: 10),
        // Column with zone labels.
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zone 1: 0-120', style: TextStyle(fontSize: 12, color: Colors.blue)),
            Text('Zone 2: 121-140', style: TextStyle(fontSize: 12, color: Colors.green)),
            Text('Zone 3: 141-160', style: TextStyle(fontSize: 12, color: Colors.yellow[700])),
            Text('Zone 4: 161-180', style: TextStyle(fontSize: 12, color: Colors.orange)),
            Text('Zone 5: 181-200', style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
      ],
    );
  }
}
