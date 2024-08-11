import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_sky_mobile_app/screens/expand_farm_screen.dart';

/* 
This screen displays the details of a farm, 
including the number of rows, columns, and solar panels.
It also displays the status and serial number of each solar panel in a grid view.
and allows the user to navigate to the ExpandFarmScreen to edit the farm details.
 */
enum PanelStatus { healthy, faulty, empty }

class FarmDetailsScreen extends StatefulWidget {
  final String farmId, farmName;
  final int rows, columns, solarPanels;

  const FarmDetailsScreen({
    Key? key,
    required this.farmId,
    required this.farmName,
    required this.rows,
    required this.columns,
    required this.solarPanels,
  }) : super(key: key);

  @override
  _FarmDetailsScreenState createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  List<List<PanelStatus>> panelStatuses = [];
  Map<String, String> panelSerialNumbersMap = {};
  late String farmName; // Mutable state variable for farm name
  late int rows,
      columns,
      solarPanels; // Mutable state variables for rows, columns, and solar panels

  @override
  void initState() {
    // Initialize the mutable state variables with the initial widget values
    farmName = widget.farmName;
    rows = widget.rows;
    columns = widget.columns;
    solarPanels = widget.solarPanels;

    // Initialize the panel statuses using the mutable state variables
    super.initState();
    panelStatuses = List.generate(widget.rows,
        (_) => List.generate(widget.columns, (_) => PanelStatus.empty));
    fetchPanelData();
  }

  // this method is about fetching the panel data from Firestore
  void fetchPanelData() async {
    // Clear the map before fetching 
    panelSerialNumbersMap.clear();
    // Fetch panel data from Firestore
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('farms')
        .doc(widget.farmId)
        .collection('panels')
        .get();

    // once the data is fetched, update the panel statuses and serial numbers
    snapshot.docs.forEach((doc) {
      final data = doc.data();
      final int row = data['row'] as int;
      final int column = data['column'] as int;
      final bool statusBool = data['panelStatus'] as bool;
      final String serialNumber = data['serialNumber'] ?? '';

      // Using a compound key 'row_column' to uniquely identify each panel
      String key = "${row}_${column}";
      // Store the serial number in the map using the compound key
      panelSerialNumbersMap[key] = serialNumber;
      // Update the panel status based on the fetched data
      if (row < widget.rows && column < widget.columns) {
        setState(() {
          panelStatuses[row][column] =
          // if the panel status is true, set it to healthy, otherwise set it to faulty
              statusBool ? PanelStatus.healthy : PanelStatus.faulty;
        });
      }
    });
  }

  // this method is about building the panel widget based on the status of the panel
  Widget buildPanel(int row, int column) {
    // Get the status of the panel at the given row and column
    final PanelStatus status = panelStatuses[row][column];
    // Using a compound key 'row_column' to uniquely identify each panel
    String key = "${row}_${column}";
    // Get the serial number of the panel using the compound key
    String? serialNumber = panelSerialNumbersMap[key];
    // Initialize the icon and color based on the panel status
    IconData? iconData;
    Color? iconColor;

    //it is just a switch case to determine the icon and color based on the status of the panel
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
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
        );
    }

    // Returning a widget that shows an icon and a serial number for healthy and faulty panels
    return Container(
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
    );
  }

  // this method is about building the farm details widget which includes
  // the number of rows, columns, and number of solar panels
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
        //it will just fetch the farm details from the widget and display them
        Text('Rows: ${widget.rows}'),
        Text('Columns: ${widget.columns}'),
        Text('Total Solar Panels: ${widget.solarPanels}'),
        Divider(),
      ],
    );
  }
  // this method is about building the status legend widget which includes
  // the legend for healthy, faulty, and empty panels 
  //legend means the description of the icons that are used in the grid 
  //view to represent the status of the panel
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

// this method is about the whole UI of the farm details screen, AKA virtual farm
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F004F),
        title: Text(
          //widget.farmName,
          farmName,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      //here we have a column widget that contains the farm details, status legend, 
      //and the grid view of the panels which builds the whole UI of the farm details screen
      body: Column(
        children: [
          buildFarmDetails(),
          buildStatusLegend(),
          Expanded(
            //here we have a grid view that contains the panels 
            child: GridView.builder(
              //first we have the item count which is the number of panels in the farm
              itemCount: widget.rows * widget.columns, // itemcount is calculated by multiplying the number of rows and columns
              //then we have the grid delegate which is the number of columns in the grid
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( // to explain it in details, the grid delegate is a widget that controls the layout of the grid view and it takes the number of columns as a parameter and it is set to the number of columns in the farm 
                crossAxisCount: widget.columns, // the number of columns in the grid view is set to the number of columns in the farm
              ),
              //then we have the item builder which is a function that builds the panel widget
              itemBuilder: (BuildContext context, int index) {
                //there are two variables row and column that are calculated based on the index
                int row = index ~/ widget.columns;
                int col = index % widget.columns;
                return buildPanel(row, col);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.aspect_ratio, color: Colors.white, size: 20),
          label: const Text('Expand or Shrink Farm',
              style: TextStyle(fontSize: 18, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            primary: const Color(0xFF008955),
            minimumSize: const Size(double.infinity, 55),
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          onPressed: navigateToEditFarmScreen,
        ),
      ),
    );
  }

  // this method is about navigating to the expand/shrink farm screen
  void navigateToEditFarmScreen() {
    //first, we navigate to the expand farm screen and pass the farm details to it
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
      //then we wait for the result from the expand farm screen
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
          panelStatuses = List.generate(widget.rows,
              (_) => List.generate(widget.columns, (_) => PanelStatus.empty));
          // Re-fetch the panel data for the updated farm
          fetchPanelData();
        });
      }
    });
  }
}
