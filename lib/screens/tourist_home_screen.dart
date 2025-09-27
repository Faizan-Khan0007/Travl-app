import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_app/screens/digital_id_screen.dart';
import 'package:travel_app/screens/tourist_dashboard.dart';

class TouristHomeScreen extends StatefulWidget {
  const TouristHomeScreen({super.key});

  @override
  _TouristHomeScreenState createState() => _TouristHomeScreenState();
}

class _TouristHomeScreenState extends State<TouristHomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const TouristDashboard(),
    const DigitalIDScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourist Safety Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Digital ID'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPanicConfirmation(context),
        label: const Text('PANIC'),
        icon: const Icon(Icons.sos),
        backgroundColor: Colors.red,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showPanicConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Panic Alert'),
        content: const Text('This will immediately share your location with the nearest authorities. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _triggerPanicAlert();
              Navigator.of(ctx).pop();
            },
            child: const Text('Yes, I Need Help'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerPanicAlert() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      Position position = await _determinePosition();
      final userDoc = await FirebaseFirestore.instance.collection('tourists').doc(user.uid).get();

      await FirebaseFirestore.instance.collection('alerts').add({
        'touristId': user.uid,
        'touristName': userDoc.data()?['name'] ?? 'N/A',
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Also update tourist status
      await FirebaseFirestore.instance.collection('tourists').doc(user.uid).update({'status': 'distress'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Panic alert sent successfully! Help is on the way.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send alert: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }
}