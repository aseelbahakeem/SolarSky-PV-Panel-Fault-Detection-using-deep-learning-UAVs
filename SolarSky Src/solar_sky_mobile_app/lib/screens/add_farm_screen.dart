import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solar_sky_mobile_app/screens/virtual_farm_screen.dart';

/* this page is used to add a new farm to the user's account 
and navigate to the VirtualFarmScreen to add solar panels to the farm*/

class AddFarmScreen extends StatefulWidget {
  // final Function onFarmAdded;
  const AddFarmScreen({Key? key}) : super(key: key);

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _solarPanelsController = TextEditingController();
  final TextEditingController _rowsController = TextEditingController();
  final TextEditingController _columnsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addFarm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No user found!'), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final int rows = int.tryParse(_rowsController.text.trim()) ?? 0;
    final int columns = int.tryParse(_columnsController.text.trim()) ?? 0;
    final int solarPanels =
        int.tryParse(_solarPanelsController.text.trim()) ?? 0;
    final String farmName = _farmNameController.text.trim();

    if (solarPanels > (rows * columns)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'The number of solar panels cannot exceed the size of the farm.'),
            backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Create a new farm document
    DocumentReference newFarmRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .add({
      'InspectionStarted': false,
      'farmName': farmName,
      'solarPanels': solarPanels,
      'rows': rows,
      'columns': columns,
      // 'inspectionTimestamp': FieldValue.serverTimestamp(),
    });

    // After successfully adding the farm, notify the FarmScreen
    // widget.onFarmAdded();
    // Navigate to VirtualFarmScreen with the new farmId
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => VirtualFarmScreen(
        farmId: newFarmRef.id, // Pass the newly created farmId here
        rows: rows,
        columns: columns,
        solarPanelsLimit: solarPanels,
      ),
    ));
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _solarPanelsController.dispose();
    _rowsController.dispose();
    _columnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Farm',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0XFF2F004F), // AppBar color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    buildTextField(_farmNameController, 'Enter farm name'),
                    buildTextField(_solarPanelsController,
                        'How many solar panels do you have'),
                    buildTextField(_rowsController, 'Number of rows'),
                    buildTextField(_columnsController, 'Number of columns'),
                    const SizedBox(height: 310),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFF008955), // Button color
                        minimumSize: const Size(double.infinity, 57),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      onPressed: _addFarm,
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF584175)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF584175), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF584175), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF584175), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label.';
          }
          return null;
        },
        keyboardType: label == 'How many solar panels do you have'
            ? TextInputType.number
            : TextInputType.text,
      ),
    );
  }
}
