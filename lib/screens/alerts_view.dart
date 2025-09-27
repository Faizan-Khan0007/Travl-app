import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlertsView extends StatelessWidget {
  const AlertsView({super.key});

  String _formatTime(DateTime time) {
    return DateFormat('MMM d, yyyy – h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "✅ No active alerts right now",
              style: TextStyle(color: Colors.green, fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var alert = snapshot.data!.docs[index];
            var data = alert.data() as Map<String, dynamic>;
            GeoPoint loc = data['location'];
            DateTime time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            String touristName = data['touristName'] ?? 'Unknown Tourist';
            String initials = touristName.isNotEmpty ? touristName[0].toUpperCase() : '?';

            bool isResolved = data['status'] == 'resolved';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isResolved ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isResolved ? Colors.green : Colors.red,
                  child: Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  touristName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📍 ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}"),
                    Text("⏰ ${_formatTime(time)}"),
                    const SizedBox(height: 4),
                    Text(
                      isResolved ? "Status: Resolved ✅" : "Status: Active 🚨",
                      style: TextStyle(
                        color: isResolved ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                trailing: !isResolved
                    ? IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                        onPressed: () => alert.reference.update({'status': 'resolved'}),
                        tooltip: 'Mark as Resolved',
                      )
                    : null,
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

