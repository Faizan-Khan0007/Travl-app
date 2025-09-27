import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveMapView extends StatelessWidget {
  const LiveMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Listen to tourists who have tracking enabled
      stream: FirebaseFirestore.instance
          .collection('tourists')
          .where('is_tracking_active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No tourists are actively sharing their location."));
        }
        
        Set<Marker> markers = {};
        for (var doc in snapshot.data!.docs) {
          try {
            var data = doc.data() as Map<String, dynamic>;
            if (data['current_location'] != null && data['current_location'] is GeoPoint) {
              GeoPoint pos = data['current_location'];
              String status = data['status'] ?? 'normal';

              BitmapDescriptor markerColor;
              switch (status) {
                case 'distress':
                  markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
                  break;
                case 'anomaly':
                  markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
                  break;
                default:
                  markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
                  break;
              }

              markers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(pos.latitude, pos.longitude),
                  infoWindow: InfoWindow(title: data['name'], snippet: "Status: $status"),
                  icon: markerColor,
                ),
              );
            }
          } catch (e) {
            print('Error processing tourist document ${doc.id}: $e');
          }
        }

        return GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(25.2423, 87.0100), // Center of Bhagalpur
            zoom: 12,
          ),
          markers: markers,
        );
      },
    );
  }
}