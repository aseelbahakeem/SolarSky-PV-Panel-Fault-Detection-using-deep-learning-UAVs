import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum PanelStatus { healthy, faulty, empty }

class ReportVirtualFarmScreen extends StatefulWidget {
  final String reportId;

  const ReportVirtualFarmScreen({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  @override
  _ReportVirtualFarmScreenState createState() =>
      _ReportVirtualFarmScreenState();
}

class _ReportVirtualFarmScreenState extends State<ReportVirtualFarmScreen> {
  List<List<PanelStatus>> panelStatuses = [];
  Map<String, String> panelSerialNumbersMap = {};
  late String farmName; // Mutable state variable for farm name
  late int rows,
      columns,
      solarPanels; // Mutable state variables for rows, columns, and solar panels

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    rows = 0;
    columns = 0;
    farmName = '';
    panelStatuses = [];
    panelSerialNumbersMap = {};
    solarPanels = 0;
    fetchReportPanelData();
  }

  void fetchReportPanelData() async {
    final reportSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('reports')
        .doc(widget.reportId)
        .get();

    if (reportSnapshot.exists) {
      final reportData = reportSnapshot.data()!;
      setState(() {
        rows = reportData['rows'] ?? 0;
        columns = reportData['columns'] ?? 0;
        farmName = reportData['farmName'] ?? '';
        solarPanels = reportData['totalNumberOfPanels'] ?? 0;
        panelStatuses = List.generate(
            rows, (_) => List.generate(columns, (_) => PanelStatus.empty));
      });

      final panelsSnapshot =
          await reportSnapshot.reference.collection('panels').get();

      for (var doc in panelsSnapshot.docs) {
        final data = doc.data();
        final row = data['row'];
        final column = data['column'];
        final isHealthy = data['status'] == 'healthy';

        // Check if the panel actually exists before setting the status
        if (row < rows && column < columns) {
          setState(() {
            panelStatuses[row][column] =
                isHealthy ? PanelStatus.healthy : PanelStatus.faulty;
            panelSerialNumbersMap['$row\_$column'] = data['serialNumber'];
          });
        }
      }
    }
  }

  Widget buildPanel(int row, int column) {
    // Use PanelStatus to determine the panel's current state
    PanelStatus status = panelStatuses.isNotEmpty
        ? panelStatuses[row][column]
        : PanelStatus.empty;
    // Adjust the displayRow and displayColumn to start counting from 1
    int displayRow = row + 1;
    int displayColumn = column + 1;
    String key = "$row\_$column";
    String serialNumber = panelSerialNumbersMap[key] ?? '';

    // Create a GestureDetector to handle taps on the panel
    return GestureDetector(
      onTap: () {
        // Only show a dialog if the panel is healthy or faulty
        if (status != PanelStatus.empty) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Panel Details'),
                content: Text(
                    'Panel at row $displayRow, column $displayColumn is ${status == PanelStatus.healthy ? "healthy" : "faulty"}. Serial Number: $serialNumber'),
                actions: <Widget>[
                  TextButton(
                    child: Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display an icon based on the panel's status
            if (status != PanelStatus.empty) // Check for non-empty status
              Icon(
                status == PanelStatus.healthy
                    ? Icons.check
                    : Icons.error_outline,
                color:
                    status == PanelStatus.healthy ? Colors.green : Colors.red,
              ),
            // Show the serial number of the panel if it's not empty
            if (serialNumber.isNotEmpty)
              Text(serialNumber, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget buildPanelIcon(IconData icon, Color color, String serialNumber) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(serialNumber, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget buildEmptyPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
    );
  }

  Widget buildFarmDetails() {
    // Assumes that rows, columns, and solarPanels are fetched and stored in state variables
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 8.0, top: 14.0, bottom: 8.0, right: 8.0),
          child: Text(
            'Virtual Farm Details',
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        Text('Rows: $rows'), // Use state variable
        Text('Columns: $columns'), // Use state variable
        // The total number of solar panels might need to be fetched or calculated
        Text('Total Solar Panels: $solarPanels'), // Use state variable
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
    if (rows == 0 && columns == 0) {
      // If rows and columns are not yet determined, show a loading indicator
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F004F),
        title: Text(farmName),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          buildFarmDetails(),
          buildStatusLegend(), // Call the method that builds farm details
          Expanded(
            // Use Expanded to fill the remaining space after the farm details
            child: GridView.builder(
              // Create a grid with a number of cells equal to rows * columns
              itemCount: rows * columns,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
              ),
              itemBuilder: (_, index) {
                // Determine the row and column of the current cell
                final row = (index ~/ columns) + 1;
                final column = (index % columns) + 1;
                return GestureDetector(
                  onTap: () {
                    // Show a dialog with panel details when tapped
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        // Access the status for the dialog
                        final status = panelStatuses[row - 1][column - 1];
                        return AlertDialog(
                          title: Text('Panel Details'),
                          content: Text(
                              'Panel at row $row, column $column is ${status == PanelStatus.healthy ? "healthy" : status == PanelStatus.faulty ? "faulty" : "empty"}. Serial Number: ${panelSerialNumbersMap["$row\_$column"]}'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: buildPanel(
                      row - 1,
                      column -
                          1), // Use the adjusted indices for accessing arrays
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
