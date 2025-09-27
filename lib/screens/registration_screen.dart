import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Store additional user info in Firestore
      await FirebaseFirestore.instance.collection('tourists').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'kyc_id': _idController.text.trim(),
        'itinerary': _itineraryController.text.trim(),
        'emergency_contact': _emergencyContactController.text.trim(),
        'safety_score': 95.0, // Simulated AI Score
        'is_tracking_active': false,
        'current_location': const GeoPoint(25.2423, 87.0100), // Default to Bhagalpur
        'last_updated': Timestamp.now(),
        'status': 'normal', // 'normal', 'distress', 'anomaly'
      });

      if(mounted) Navigator.of(context).pop();

    } on FirebaseAuthException catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: ${e.message}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tourist Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
              TextFormField(controller: _idController, decoration: const InputDecoration(labelText: 'Aadhaar/Passport No.'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _itineraryController, decoration: const InputDecoration(labelText: 'Trip Itinerary (e.g., Bhagalpur -> Mandar Hills)'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _emergencyContactController, decoration: const InputDecoration(labelText: 'Emergency Contact Number'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _register, child: const Text('Register')),
            ],
          ),
        ),
      ),
    );
  }
}

