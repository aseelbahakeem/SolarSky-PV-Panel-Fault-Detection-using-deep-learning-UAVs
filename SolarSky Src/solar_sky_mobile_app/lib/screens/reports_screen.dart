import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_sky_mobile_app/widgets/custom_drawer.dart';
import 'package:solar_sky_mobile_app/screens/report_details_screen.dart';
import 'dart:async';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedDrone = 'All';
  List<String> droneNames = ['All']; // Initialize with 'All' option

  @override
  void initState() {
    super.initState();
    fetchDroneNames();
    listenToInspectionActivity();
  }

  StreamSubscription? _inspectionSubscription;

  void listenToInspectionActivity() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _inspectionSubscription?.cancel(); // Cancel any existing subscription.

    _inspectionSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final farmDoc = snapshot.docs.first;
        final isInspectionActive = farmDoc['InspectionStarted'] ?? false;
        if (isInspectionActive) {
          generateReport().then((_) {
            farmDoc.reference.update({'InspectionStarted': false});
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _inspectionSubscription?.cancel(); // Dispose of the subscription.
    super.dispose();
  }

  Future<void> fetchDroneNames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final droneSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('drones')
        .get();

    List<String> names = ['All']; // 'All' option to show all reports
    for (var doc in droneSnapshot.docs) {
      names.add(doc.data()['name']);
    }

    setState(() {
      droneNames = names;
    });
  }

  Stream<QuerySnapshot> getReportStream() {
    var user = FirebaseAuth.instance.currentUser;
    if (selectedDrone == 'All') {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('reports')
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('reports')
          .where('droneName', isEqualTo: selectedDrone)
          .snapshots();
    }
  }

  String formatDate(DateTime date) {
    // Using built-in DateTime methods to format date
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> generateReport() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to generate a report.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final farmsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .get();

    for (var farmDoc in farmsSnapshot.docs) {
      final farmId = farmDoc.id;
      final panelsSnapshot = await farmDoc.reference.collection('panels').get();

      int healthyPanels = 0;
      int faultyPanels = 0;

      // Generating the report with a title including the current date
      final reportTitle = 'Inspection report ${formatDate(DateTime.now())}';

      // Fetch the selected drone's name
      var selectedDroneSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('drones')
          .where('isSelected', isEqualTo: true)
          .limit(1)
          .get();

      var droneName = selectedDroneSnapshot.docs.isNotEmpty
          ? selectedDroneSnapshot.docs.first.data()['name'] as String
          : 'No drone selected';

      // Create a report at the same level as farms and drones
      DocumentReference reportRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .add({
        'title': reportTitle,
        'totalNumberOfPanels': panelsSnapshot.docs.length,
        'numberOfHealthyPanels': healthyPanels,
        'numberOfFaultyPanels': faultyPanels,
        // 'faultyPanels': faultyPanelSerialNumbers,
        'farmId': farmId,
        'farmName': farmDoc['farmName'], // Add the farm name to the report
        'droneName': droneName,
        'timestamp': FieldValue.serverTimestamp(),
        'rows': farmDoc['rows'],
        'columns': farmDoc['columns'],
      });

      // Add faulty panels to the sub-collection
      for (var panelDoc in panelsSnapshot.docs) {
        final panelData = panelDoc.data();
        final isHealthy = panelData['panelStatus'] as bool;
        if (!isHealthy) {
          faultyPanels++;
          // Add each faulty panel as a document in the 'faultyPanels' sub-collection
          await reportRef.collection('faultyPanels').add({
            'serialNumber': panelData['serialNumber'],
            'row': panelData['row'],
            'column': panelData['column'],
          });
        } else {
          healthyPanels++;
        }
      }

      // Update the counts after processing all panels
      await reportRef.update({
        'numberOfHealthyPanels': healthyPanels,
        'numberOfFaultyPanels': faultyPanels,
      });

      // Iterate over all panels and add them to the report's panels collection
      for (var panelDoc in panelsSnapshot.docs) {
        final panelData = panelDoc.data() as Map<String, dynamic>;
        final isHealthy = panelData['panelStatus'] as bool;

        // The document ID is composed of 'row_column' for the panel's location
        String panelId = '${panelData['row']}_${panelData['column']}';
        await reportRef.collection('panels').doc(panelId).set({
          'serialNumber': panelData['serialNumber'],
          'status':
              isHealthy ? 'healthy' : 'faulty', // Store the status as a string
          'row': panelData['row'],
          'column': panelData['column'],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully!'),
          backgroundColor: Color.fromARGB(255, 59, 136, 62),
        ),
      );
    }
  }

  // Method to delete a report
  Future<void> _deleteReport(String reportId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reports')
            .doc(reportId)
            .delete();

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // If there's an error, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          centerTitle: true,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
        ),
        body: user == null
            ? const Center(child: Text('You are not logged in.'))
            : Column(
                children: [
                  // Custom styled dropdown filter for drone names
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.white, // White color background
                        borderRadius:
                            BorderRadius.circular(10.0), // Rounded corners
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26, // Shadow color
                            blurRadius: 6.0, // Blur radius
                            offset: Offset(0, 3), // Shadow position
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedDrone,
                          icon: const Icon(
                              Icons.arrow_drop_down), // Dropdown icon
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedDrone = newValue ?? 'All';
                            });
                          },
                          items: droneNames.map<DropdownMenuItem<String>>(
                            (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            },
                          ).toList(),
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getReportStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No reports available!',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        var reports = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: reports.length,
                          itemBuilder: (context, index) {
                            var reportData =
                                reports[index].data() as Map<String, dynamic>;
                            return ListTile(
                              tileColor: const Color(0xFF866B99),
                              title: Text(
                                reportData['title'] ?? 'No Title',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 54, 43, 62),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportDetailsScreen(
                                      reportId: reports[index].id,
                                    ),
                                  ),
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Color.fromARGB(255, 54, 43, 62)),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Delete Report'),
                                        content: const Text(
                                            'Are you sure you want to delete this report?'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: const Text('Delete'),
                                            onPressed: () {
                                              _deleteReport(reports[index].id);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
        drawer: CustomDrawer(),
        backgroundColor: const Color(0XFF2F004F),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: generateReport,
        //   child: const Icon(Icons.add),
        //   tooltip: 'Generate New Report',
        // ),
      ),
    );
  }
}
