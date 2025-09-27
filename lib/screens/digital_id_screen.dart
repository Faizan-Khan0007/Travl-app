import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DigitalIDScreen extends StatelessWidget {
  const DigitalIDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tourists').doc(userId).snapshots(),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // FIXED: Check if the document exists before trying to access its data.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Could not find your user data. Please relogin."));
        }
        var userData = snapshot.data!.data() as Map<String, dynamic>;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Blockchain-Verified Digital ID", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                QrImageView(
                  data: userId, // The QR code contains the secure user ID
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Text("Scan for Verification", style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 20),
                ListTile(title: const Text("Name"), subtitle: Text(userData['name'] ?? 'N/A')),
                ListTile(title: const Text("Passport/Aadhaar"), subtitle: Text(userData['kyc_id'] ?? 'N/A')),
                ListTile(title: const Text("Itinerary"), subtitle: Text(userData['itinerary'] ?? 'N/A')),
                ListTile(title: const Text("Emergency Contact"), subtitle: Text(userData['emergency_contact'] ?? 'N/A')),
                const SizedBox(height: 80), // Space for panic button
              ],
            ),
          ),
        );
      },
    );
  }
}
