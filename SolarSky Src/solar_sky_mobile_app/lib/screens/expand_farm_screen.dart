import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_sky_mobile_app/screens/home.dart';

/*
this page is used to expand the farm and add solar panels to the farm
and add new rows and columns to the farm and delete the last row and column
and also to add or delete the panels and mark the panels as healthy or faulty
 */
enum PanelStatus { healthy, faulty, empty }

class ExpandFarmScreen extends StatefulWidget {
  final String farmId, currentFarmName;
  final int currentRows, currentColumns, currentTotalPanels;

  const ExpandFarmScreen({
    Key? key,
    required this.farmId,
    required this.currentFarmName,
    required this.currentRows,
    required this.currentColumns,
    required this.currentTotalPanels,
  }) : super(key: key);

  @override
  _ExpandFarmScreenState createState() => _ExpandFarmScreenState();
}

class _ExpandFarmScreenState extends State<ExpandFarmScreen> {
  List<List<PanelStatus>> panelStatuses = [];
  Map<String, String> panelSerialNumbersMap = {};
  late String farmName; // Mutable state variable for farm name
  late int rows,
      columns,
      solarPanels; // Mutable state variables for rows, columns, and solar panels

  @override
  void initState() {
    // Initialize the mutable state variables with the initial widget values
    // farmName = widget.farmId;
    farmName = widget.currentFarmName;
    rows = widget.currentRows;
    columns = widget.currentColumns;
    solarPanels = widget.currentTotalPanels;

    // Initialize the panel statuses using the mutable state variables
    super.initState();
    panelStatuses = List.generate(widget.currentRows,
        (_) => List.generate(widget.currentColumns, (_) => PanelStatus.empty));
    fetchPanelData();
  }

  void fetchPanelData() async {
    // Clear the map before fetching new data
    panelSerialNumbersMap.clear();
    // Fetch panel data from Firestore
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('farms')
        .doc(widget.farmId)
        .collection('panels')
        .get();

    snapshot.docs.forEach((doc) {
      final data = doc.data();
      final int row = data['row'] as int;
      final int column = data['column'] as int;
      final bool statusBool = data['panelStatus'] as bool;
      final String serialNumber = data['serialNumber'] ?? '';

      // Using a compound key 'row_column' to uniquely identify each panel
      String key = "${row}_${column}";
      panelSerialNumbersMap[key] = serialNumber;

      if (row < widget.currentRows && column < widget.currentColumns) {
        setState(() {
          panelStatuses[row][column] =
              statusBool ? PanelStatus.healthy : PanelStatus.faulty;
        });
      }
    });
  }

  Widget buildPanel(int row, int column) {
    final PanelStatus status = panelStatuses[row][column];
    String key = "${row}_${column}";
    String? serialNumber = panelSerialNumbersMap[key];
    IconData? iconData;
    Color? iconColor;

    switch (status) {
      case PanelStatus.healthy:
        iconData = Icons.check; // 'check' icon for healthy
        iconColor = Colors.green;
        break;
      case PanelStatus.faulty:
        iconData = Icons.error_outline; // 'error_outline' icon for faulty
        iconColor = Colors.red;
        break;
      case PanelStatus.empty:

        // No icon for empty panels, so we'll return an empty container.
        return InkWell(
          onTap: () => addNewPanel(row, column), // Tap to add a new panel
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: const Center(
              child: Text(
                '+', // Display a '+' sign to indicate adding a new panel
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
    }

    // Return a widget for faulty panels with a tap handler
    return InkWell(
      onDoubleTap: () =>
          togglePanelStatus(row, column), // Call to toggle status method
      onTap: () => editOrDeletePanel(
          row, column, serialNumber), // Long press to edit serial number
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: iconColor),
            if (serialNumber != null && serialNumber.isNotEmpty)
              Text(serialNumber,
                  style: TextStyle(fontSize: 12, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  void editOrDeletePanel(int row, int column, String? currentSerial) {
    TextEditingController serialController =
        TextEditingController(text: currentSerial);
    final PanelStatus status = panelStatuses[row][column];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Panel Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status != PanelStatus.empty) ...[
                TextField(
                  controller: serialController,
                  decoration: InputDecoration(hintText: 'Enter Serial Number'),
                ),
                SizedBox(height: 20),
              ],
              if (status != PanelStatus.empty)
                TextButton(
                  child: Text('Delete Panel'),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Close the panel options dialog
                    confirmDeletePanel(row, column, status);
                  },
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (status != PanelStatus.empty)
              TextButton(
                child: Text('Save'),
                onPressed: () {
                  // Here, you should update the panelSerialNumbersMap with the new serial number
                  setState(() {
                    String key = "$row\_$column";
                    panelSerialNumbersMap[key] = serialController.text;
                  });
                  Navigator.of(context).pop();
                  // updatePanelInFirestore(row, column, serialController.text,
                  //     status == PanelStatus.faulty);
                  // Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  void confirmDeletePanel(int row, int column, PanelStatus status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Panel'),
          content: Text(
              'Do you want to delete this ${status == PanelStatus.faulty ? 'faulty' : 'healthy'} panel?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                deletePanelFromFirestore(row, column);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void deletePanelFromFirestore(int row, int column) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('farms')
        .doc(widget.farmId)
        .collection('panels')
        .doc("${row}_${column}")
        .delete()
        .then((_) {
      print('Panel deleted');
      // Update local state after successful deletion
      setState(() {
        panelStatuses[row][column] = PanelStatus.empty;
        panelSerialNumbersMap.remove("${row}_${column}");
        solarPanels--; // Decrement total solar panels count
      });
    }).catchError((error) => print('Failed to delete panel: $error'));
  }

  void addNewPanel(int row, int column) {
    TextEditingController serialController = TextEditingController();
    String? errorText; // Use null to not show any error initially
    String key = "${row}_${column}"; // Define the key here

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Panel'),
              content: TextField(
                controller: serialController,
                decoration: InputDecoration(
                  hintText: 'Enter Serial Number',
                  errorText: errorText,
                ),
                onChanged: (value) {
                  // Reset error text whenever the user changes the text
                  if (errorText != null && value.isNotEmpty) {
                    setDialogState(() {
                      errorText = null;
                    });
                  }
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    String newSerial = serialController.text.trim();
                    if (newSerial.isEmpty) {
                      // Set error if serial number is empty and update the local state
                      setDialogState(() {
                        errorText = 'Serial number must not be empty';
                      });
                    } else if (panelSerialNumbersMap.containsValue(newSerial)) {
                      // Set error if serial number is not unique
                      setDialogState(() {
                        errorText = 'Serial number must be unique';
                      });
                    } else {
                      // Add new panel if serial number is not empty and is unique
                      setState(() {
                        panelSerialNumbersMap[key] = newSerial;
                        panelStatuses[row][column] = PanelStatus.healthy;
                        solarPanels++; // Increment total solar panels count
                      });
                      addPanelToFirestore(row, column, newSerial);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void togglePanelStatus(int row, int column) {
    final currentStatus = panelStatuses[row][column];

    // Toggle only if the panel is currently faulty
    if (currentStatus == PanelStatus.faulty) {
      // Update the local state
      setState(() {
        panelStatuses[row][column] = PanelStatus.healthy;
      });

      // Update the Firestore document for the panel
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('farms')
          .doc(widget.farmId)
          .collection('panels')
          .doc("${row}_${column}")
          .update({
            'panelStatus': true
          }) // true to indicate the panel is now healthy
          .then((_) => print('Panel marked as healthy'))
          .catchError(
              (error) => print('Failed to update panel status: $error'));
    }
  }

  void addPanelToFirestore(int row, int column, String serialNumber) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('farms')
        .doc(widget.farmId)
        .collection('panels')
        .doc("${row}_${column}")
        .set({
          'serialNumber': serialNumber,
          'row': row,
          'column': column,
          'panelStatus': true, // or false based on your app logic
        })
        .then((_) => print('New panel added'))
        .catchError((error) => print('Failed to add new panel: $error'));
  }

  void updatePanelInFirestore(
      int row, int column, String serialNumber, bool isFaulty) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('farms')
        .doc(widget.farmId)
        .collection('panels')
        .doc("${row}_${column}")
        .update({
          'serialNumber': serialNumber,
          'panelStatus': !isFaulty,
        })
        .then((_) => print('Panel updated'))
        .catchError((error) => print('Failed to update panel: $error'));
  }

  Widget buildFarmDetails() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 8.0, top: 14.0, bottom: 8.0, right: 8.0),
          child: Text(
            'Farm Details',
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        Text('Rows: ${widget.currentRows}'),
        Text('Columns: ${widget.currentColumns}'),
        Text(
            'Total Solar Panels: ${solarPanels}'), // Updated to show state variable
        Divider(),
      ],
    );
  }

  Widget buildStatusLegend() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Healthy Panel
          Row(
            children: [
              Icon(Icons.check, color: Colors.green),
              SizedBox(width: 8),
              Text('Healthy Panel'),
            ],
          ),
          // Faulty Panel
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Faulty Panel'),
            ],
          ),
          // Empty Panel
          Row(
            children: [
              Icon(Icons.check_box_outline_blank, color: Colors.grey),
              SizedBox(width: 8),
              Text('Empty Panel'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F004F),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          farmName,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false, // Hide the back button
      ),
      body: Column(
        children: [
          buildFarmDetails(),
          buildStatusLegend(), // This will display the status legend on the screen
          Expanded(
            child: GridView.builder(
              itemCount: rows * columns,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
              ),
              itemBuilder: (BuildContext context, int index) {
                int row = index ~/ columns;
                int col = index % columns;
                return buildPanel(row, col);
              },
            ),
          ),
          // UI for adding and deleting rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: deleteLastRow,
                  tooltip: 'Delete last row',
                ),
                Text('Rows: $rows'),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addNewRow,
                  tooltip: 'Add new row',
                ),
              ],
            ),
          ),
          // UI for adding and deleting columns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: deleteLastColumn,
                  tooltip: 'Delete last column',
                ),
                Text('Columns: $columns'),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addNewColumn,
                  tooltip: 'Add new column',
                ),
              ],
            ),
          ),
          // 'Save Changes' button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            // child: ElevatedButton(
            //   onPressed: saveChanges,
            //   child: const Text('Save Changes'),
            //   style: ElevatedButton.styleFrom(
            //     minimumSize: const Size(double.infinity, 50),
            //     textStyle: const TextStyle(fontSize: 20),
            //   ),
            // ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: const Color(0xFF008955),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  // Shape property to customize the button's border
                  borderRadius: BorderRadius.circular(9),
                ),

                // Set the button size
              ),
              onPressed: saveChanges,
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool canAddRow() {
    if (panelStatuses.isEmpty)
      return true; // If there are no rows, a new row can be added
    List<PanelStatus> lastRow = panelStatuses.last;
    // Check if at least one panel in the last row is not empty
    return lastRow.any((panelStatus) => panelStatus != PanelStatus.empty);
  }

  void addNewRow() {
    if (canAddRow()) {
      // Update the local state to reflect the new row
      setState(() {
        // Create a new row with empty panel statuses
        List<PanelStatus> newRow =
            List.generate(widget.currentColumns, (_) => PanelStatus.empty);
        // Add the new row to the panel statuses
        panelStatuses.add(newRow);
        // Increment the row count
        rows++;
      });
    } else {
      // Show a message if a new row cannot be added
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Cannot add a new row. The last row is completely empty."),
        ),
      );
    }
  }

  bool canDeleteRow() {
    if (panelStatuses.isEmpty) {
      return false; // No rows to delete.
    }
    // Check if the last row is completely empty.
    return panelStatuses.last.every((status) => status == PanelStatus.empty);
  }

  void deleteLastRow() {
    if (canDeleteRow()) {
      setState(() {
        panelStatuses.removeLast(); // Remove the last row.
        rows--; // Decrement the row count.
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Cannot delete the last row. It is not completely empty."),
        ),
      );
    }
  }

  bool canAddColumn() {
    // Check if at least one panel in the rightmost column is not empty
    return panelStatuses.any((List<PanelStatus> row) =>
        row.isNotEmpty && row.last != PanelStatus.empty);
  }

  void addNewColumn() {
    if (canAddColumn()) {
      setState(() {
        // Add a new empty panel to each row
        for (List<PanelStatus> row in panelStatuses) {
          row.add(PanelStatus.empty);
        }
        columns++; // Increment the column count
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Cannot add a new column. The rightmost column is completely empty.")));
    }
  }

  bool canDeleteColumn() {
    // Check if the last column is completely empty
    return panelStatuses.every((List<PanelStatus> row) =>
        row.isNotEmpty && row.last == PanelStatus.empty);
  }

  void deleteLastColumn() {
    if (canDeleteColumn()) {
      setState(() {
        // Remove the last panel from each row
        for (var row in panelStatuses) {
          row.removeLast();
        }
        columns--; // Decrement the column count
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Cannot delete the last column. It is not completely empty.")));
    }
  }

  void saveChanges() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          Center(child: CircularProgressIndicator()),
    );

    try {
      int totalPanels = 0; // Initialize a counter for the panels
      // Update Firestore with the current state (rows, columns, panels data)
      for (int row = 0; row < panelStatuses.length; row++) {
        for (int col = 0; col < panelStatuses[row].length; col++) {
          String panelKey = "${row}_${col}";
          PanelStatus status = panelStatuses[row][col];
          String? serialNumber = panelSerialNumbersMap[panelKey];

          if (status != PanelStatus.empty) {
            totalPanels++; // Count the panel if it's not empty
            // Update or add new panel information
            await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('farms')
                .doc(widget.farmId)
                .collection('panels')
                .doc(panelKey)
                .set({
              'row': row,
              'column': col,
              'serialNumber': serialNumber ?? "",
              'panelStatus': status == PanelStatus.healthy
            });
          } else {
            // Remove empty panels from Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('farms')
                .doc(widget.farmId)
                .collection('panels')
                .doc(panelKey)
                .delete();
          }
        }
      }

      // Update the farm's rows and columns count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('farms')
          .doc(widget.farmId)
          .update({
        'rows': rows,
        'columns': columns,
        // 'solarPanels': totalPanels, // The updated total number of panels
        'solarPanels': totalPanels, // The updated total number of panels
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All changes saved successfully.')));

      setState(() {
        solarPanels =
            totalPanels; // Set solarPanels to the calculated totalPanels
      });
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
    }
    // After saving, navigate to the HomeScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (Route<dynamic> route) =>
          false, // This will remove all the routes below the HomeScreen
    );
  }

  void navigateToEditFarmScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpandFarmScreen(
          farmId: widget.farmId,
          currentFarmName: farmName, // Pass mutable state variable
          currentRows: rows, // Pass mutable state variable
          currentColumns: columns, // Pass mutable state variable
          currentTotalPanels: solarPanels, // Pass mutable state variable
        ),
      ),
    ).then((result) {
      if (result != null) {
        // If the EditFarmScreen returns updated farm details, update the state
        setState(() {
          // Update mutable state variables with the new values
          farmName = result['farmName'];
          rows = result['rows'];
          columns = result['columns'];
          solarPanels = result['totalPanels'];
          // Refresh the panel statuses to reflect the updated farm size
          panelStatuses = List.generate(
              widget.currentRows,
              (_) => List.generate(
                  widget.currentColumns, (_) => PanelStatus.empty));
          // Refetch the panel data for the updated farm
          fetchPanelData();
        });
      }
    });
  }
}
