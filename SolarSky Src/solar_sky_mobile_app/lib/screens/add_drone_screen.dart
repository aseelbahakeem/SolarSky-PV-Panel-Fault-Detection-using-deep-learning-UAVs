import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDroneScreen extends StatefulWidget {
  const AddDroneScreen({Key? key}) : super(key: key);

  @override
  _AddDroneScreenState createState() => _AddDroneScreenState();
}

class _AddDroneScreenState extends State<AddDroneScreen> {
  final TextEditingController _droneNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  Future<void> _saveDrone() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to add a drone.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Add the new drone directly under the 'drones' collection for this user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('drones')
          .add({
        'name': _droneNameController.text.trim(),
        'isSelected': false,
        
      });

      // Clear the text field
      _droneNameController.clear();

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drone added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // pop back to previous screen
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _droneNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Drone',
            style: TextStyle(
                color: Color(0xFF2A2A2A), fontWeight: FontWeight.w500)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2A2A2A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 30,
                    ),
                    TextFormField(
                      controller: _droneNameController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Drone name',
                        fillColor: Color(0xFFC1B2CA),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a drone name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFF008955),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 57),
                      ),
                      onPressed: _saveDrone,
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: const Color(0xFF2F004F),
    );
  }
}
