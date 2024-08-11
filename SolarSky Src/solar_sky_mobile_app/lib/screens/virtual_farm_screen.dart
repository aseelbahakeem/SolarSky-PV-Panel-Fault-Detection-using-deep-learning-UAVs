import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_sky_mobile_app/screens/farm_screen.dart';
import 'package:solar_sky_mobile_app/screens/home.dart';

/* 
this page is the virtual farm screen where the user inistially 
can add solar panels to the farm, and save the farm configuration
and navigate to the HomeScreen, and also to display the instructions
for the virtual farm
 */

class PanelData {
  final int row;
  final int column;
  String serialNumber;
  bool selected; // Added to track if the panel is selected

  PanelData({
    required this.row,
    required this.column,
    required this.serialNumber,
    this.selected = false, // Default to not selected
  });
}

class VirtualFarmScreen extends StatefulWidget {
  final String farmId;
  final int rows;
  final int columns;
  final int solarPanelsLimit;

  const VirtualFarmScreen({
    Key? key,
    required this.farmId, // Changed to farmId
    required this.rows,
    required this.columns,
    required this.solarPanelsLimit,
  }) : super(key: key);

  @override
  _VirtualFarmScreenState createState() => _VirtualFarmScreenState();
}

class _VirtualFarmScreenState extends State<VirtualFarmScreen> {
  late List<List<PanelData?>> grid;
  int placedPanels = 0;
  bool _isSaving = false; // New flag to prevent multiple saves

  @override
  void initState() {
    super.initState();
    grid = List.generate(
      widget.rows,
      (_) => List.generate(widget.columns, (_) => null),
    );
  }

  Future<void> _showSerialNumberDialog(int row, int col) async {
    // Only proceed if the number of placed panels is less than the limit
    if (placedPanels >= widget.solarPanelsLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You've reached the limit of solar panels.")),
      );
      return; // Exit the function if the limit is reached
    }

    TextEditingController serialNumberController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Serial Number'),
          content: TextField(
            controller: serialNumberController,
            decoration: const InputDecoration(hintText: 'Serial Number'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(serialNumberController.text.trim());
              },
            ),
          ],
        );
      },
    ).then((serialNumber) {
      if (serialNumber != null && serialNumber.isNotEmpty) {
        setState(() {
          grid[row][col] =
              PanelData(row: row, column: col, serialNumber: serialNumber);
          placedPanels++;
        });
      }
    });
  }

  Widget _buildGridItem(BuildContext context, int index) {
    int row = index ~/ widget.columns;
    int col = index % widget.columns;
    PanelData? panel = grid[row][col];

    // Tap to add or show options for existing panel
    return GestureDetector(
      onTap: panel == null
          ? () => _addOrEditPanel(row, col, null)
          : () => _showOptionsDialog(row, col),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Color.fromARGB(255, 0, 0, 0)),
          color: panel != null ? Colors.green[200] : Colors.grey[300],
        ),
        child: Center(
          child:
              Text(panel?.serialNumber ?? '+', style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Future<void> _addOrEditPanel(int row, int col, PanelData? panel) async {
    TextEditingController serialNumberController =
        TextEditingController(text: panel?.serialNumber);
    String? errorText;

    bool isSerialNumberUnique(String serial) {
      for (var rowList in grid) {
        for (var panelData in rowList) {
          if (panelData != null &&
              panelData.serialNumber == serial &&
              panelData != panel) {
            return false;
          }
        }
      }
      return true;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(panel == null ? 'Add Serial Number' : 'Edit Serial Number'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return TextField(
              controller: serialNumberController,
              decoration: InputDecoration(
                hintText: 'Serial Number',
                errorText: errorText,
              ),
              autofocus: true,
              onChanged: (value) {
                // Reset error text whenever the user changes the text
                setState(() {
                  errorText = null;
                });
              },
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              String trimmedSerial = serialNumberController.text.trim();
              // Check if the serial number field is not empty
              if (trimmedSerial.isEmpty) {
                errorText = 'Serial number must not be empty';
                (context as Element).markNeedsBuild(); // Request a rebuild
                return; // Stay in dialog
              }
              // Check if the serial number is unique
              if (!isSerialNumberUnique(trimmedSerial)) {
                errorText = 'Serial number must be unique';
                (context as Element).markNeedsBuild(); // Request a rebuild
                return; // Stay in dialog
              }
              // If the code reaches this point, the input is valid
              setState(() {
                if (panel == null) {
                  // Add new panel if not existing
                  grid[row][col] = PanelData(
                      row: row, column: col, serialNumber: trimmedSerial);
                } else {
                  // Update existing panel's serial number
                  panel.serialNumber = trimmedSerial;
                }
                placedPanels++;
              });
              Navigator.of(context).pop(); // Exit dialog on successful input
            },
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog(int row, int col) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Panel Options'),
        content: const Text('Choose an option for the panel'),
        actions: [
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              setState(() {
                grid[row][col] = null;
                placedPanels--; // Decrement the count of placed panels
              });
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.of(context).pop();
              _addOrEditPanel(row, col, grid[row][col]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        childAspectRatio: 1.0, // Added to make grid cells square
      ),
      itemCount: widget.rows * widget.columns,
      itemBuilder: _buildGridItem,
    );
  }

  Future<void> _saveFarmConfiguration() async {
    if (_isSaving) return; // Prevent multiple save attempts
    _isSaving = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to save.')),
      );
      _isSaving = false; // Reset saving flag
      return;
    }

    List<Map<String, dynamic>> panelsData = [];
    bool isComplete = true;

    for (var rows in grid) {
      for (var panel in rows) {
        if (panel == null) {
          isComplete = false;
          continue;
        }
        panelsData.add({
          'row': panel.row,
          'column': panel.column,
          'serialNumber': panel.serialNumber,
          'panelStatus': true, // Add status field and initialize as true
        });
      }
    }

    if (panelsData.length != widget.solarPanelsLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Number of panels must be ${widget.solarPanelsLimit}.'),
        ),
      );
      _isSaving = false; // Reset saving flag
      return;
    }

    try {
      DocumentReference farmRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('farms')
          .doc(widget.farmId); // Using farmId here

      await farmRef.update({
        'rows': widget.rows,
        'columns': widget.columns,
        'solarPanelsLimit': widget.solarPanelsLimit,
      });

      // Add or update the panels in a subcollection
      for (var panelData in panelsData) {
        await farmRef
            .collection('panels')
            .doc('${panelData['row']}_${panelData['column']}')
            .set(panelData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm configuration saved successfully!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) =>
            false, // This ensures that all previous screens are removed from the stack
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving farm configuration: $e')),
      );
    } finally {
      _isSaving = false; // Reset saving flag upon completion
    }
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // icon: const Icon(Icons.info_outline),
        title: const Text('Instructions'),
        content: const Text(
          '1. Tap a grid cell to select the location for a new solar panel.\n'
          '2. Enter the solar panel\'s serial number in the field that appears.\n'
          '3. Press \'Confirm\' to save the serial number to the selected grid.\n'
          '4. If you need to edit or remove a serial number, tap the grid cell again. You will be presented with two options: \'Edit\' to change the serial number or \'Delete\' to remove it.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Back'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFF2F004F),
        title: const Text(
          'Add Virtual Farm',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        // Enable scrolling
        child: Column(
          children: [
            // Instruction button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ElevatedButton.icon(
                onPressed: _showInstructionsDialog,
                icon: const Icon(Icons.info_outline,
                    color: Color.fromARGB(255, 25, 25, 25)),
                label: const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 36, 36, 36),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(255, 255, 255, 255), // Button color
                  onPrimary: Colors.white, // Text color
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Grid display
            Container(
              // Wrap in a container to constrain height within SingleChildScrollView
              height: MediaQuery.of(context).size.height - 280,
              child: _buildGrid(),
            ),
            // 'Add Virtual Farm' button
            Padding(
              padding: const EdgeInsets.only(right: 20, left: 20, bottom: 20),
              child: ElevatedButton(
                onPressed: _saveFarmConfiguration,
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xFF008955),
                  minimumSize: const Size(double.infinity, 57),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'Add Virtual Farm',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
