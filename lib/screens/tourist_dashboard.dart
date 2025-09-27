import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class TouristDashboard extends StatefulWidget {
  const TouristDashboard({super.key});

  @override
  _TouristDashboardState createState() => _TouristDashboardState();
}

class _TouristDashboardState extends State<TouristDashboard> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  StreamSubscription<Position>? _positionStream;
  
  // Hardcoded high-risk zone for geofencing simulation (Mandar Hills area)
  final LatLng _highRiskZoneCenter = const LatLng(24.8344, 87.0227);
  final double _highRiskZoneRadius = 1000; // in meters
  bool _alertShown = false;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _toggleTracking(bool isActive) {
    FirebaseFirestore.instance.collection('tourists').doc(_userId).update({'is_tracking_active': isActive});
    if (isActive) {
      _startLocationUpdates();
    } else {
      _positionStream?.cancel();
    }
  }

  Future<void> _startLocationUpdates() async {
    await Permission.location.request();
    if (await Permission.location.isGranted) {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        FirebaseFirestore.instance.collection('tourists').doc(_userId).update({
          'current_location': GeoPoint(position.latitude, position.longitude),
          'last_updated': Timestamp.now(),
        });
        _checkGeofence(position);
      });
    }
  }
  
  void _checkGeofence(Position position) {
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _highRiskZoneCenter.latitude,
      _highRiskZoneCenter.longitude,
    );
    
    if (distance < _highRiskZoneRadius && !_alertShown) {
      setState(() { _alertShown = true; });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ High-Risk Zone Alert'),
          content: const Text('You are entering a designated high-risk or remote area (Mandar Hills). Please be cautious and ensure your emergency contacts are aware of your location.'),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('I Understand'))],
        ),
      );
    } else if (distance >= _highRiskZoneRadius) {
      setState(() { _alertShown = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tourists').doc(_userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // FIXED: Check if the document exists before trying to access its data.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Could not find your user data. Please relogin."));
        }
        var userData = snapshot.data!.data() as Map<String, dynamic>;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: ListTile(
                title: Text("Welcome, ${userData['name'] ?? 'Tourist'}!"),
                subtitle: Text("Safety Score: ${userData['safety_score']?.toStringAsFixed(1) ?? 'N/A'}/100"),
                trailing: const Icon(Icons.health_and_safety, color: Colors.green, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Enable Real-time Safety Tracking'),
                subtitle: const Text('Shares your location with authorities for your safety.'),
                value: userData['is_tracking_active'] ?? false,
                onChanged: _toggleTracking,
              ),
            ),
            const SizedBox(height: 16),
            const Text("AI-Based Anomaly Detection is active.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const Text("Deviations from your itinerary or prolonged inactivity will be automatically flagged.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        );
      },
    );
  }
}