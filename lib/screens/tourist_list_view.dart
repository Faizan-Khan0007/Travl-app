
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TouristListView extends StatelessWidget {
  const TouristListView({super.key});

  void _simulateAnomaly(String docId) {
    FirebaseFirestore.instance.collection('tourists').doc(docId).update({'status': 'anomaly'});
  }
  
  void _clearStatus(String docId) {
    FirebaseFirestore.instance.collection('tourists').doc(docId).update({'status': 'normal'});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tourists').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['name'] ?? 'N/A'),
                subtitle: Text("Status: ${data['status'] ?? 'normal'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.warning_amber, color: Colors.orange),
                      onPressed: () => _simulateAnomaly(doc.id),
                      tooltip: 'Simulate AI Anomaly',
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      onPressed: () => _clearStatus(doc.id),
                      tooltip: 'Clear Status',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

