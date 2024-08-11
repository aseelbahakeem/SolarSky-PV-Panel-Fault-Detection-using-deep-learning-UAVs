import 'package:flutter/material.dart';
import 'package:solar_sky_mobile_app/widgets/custom_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_sky_mobile_app/screens/add_farm_screen.dart';
import 'package:solar_sky_mobile_app/screens/farm_details_screen.dart';

/*                    
This screen displays a list of farms added by the user.
The user can add a new farm, delete a farm, or navigate to the details of a farm.
*/
class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  bool _isAddingAllowed = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    checkIfFarmExists();
  }

  //this method checks if the user has any farms
  void checkIfFarmExists() async {
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;
    // If the user is not null, check if they have any farms
    if (user != null) {
      var farmCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('farms');

      // Listen to the farm collection to check if there are any farms
      farmCollection.snapshots().listen((snapshot) {
        if (mounted) {
          setState(() {
            // Set to false if there's at least one farm
            _isAddingAllowed = snapshot.docs.isEmpty;
            _isLoading = false; // Update loading state to false after checking
          });
        }
      });
    } else {
      // In case the user is null, we assume loading is complete
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // this method deletes a farm
  Future<void> _deleteFarm(String farmId) async {
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;
    // If the user is not null, proceed with deleting the farm
    if (user != null) {
      try {
        // Reference to the farm document in the user's farms collection
        DocumentReference farmRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('farms')
            .doc(farmId);
        // First delete all documents in the 'panels' subcollection
        var panels = await farmRef.collection('panels').get();
        for (var doc in panels.docs) {
          await doc.reference.delete();
        }

        // After all subcollections are deleted, delete the farm document
        await farmRef.delete();
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farm deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Catch any errors and show an error message
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting farm: $e'),
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
          leadingWidth: 60,
          centerTitle: true,
          title: const Text('Farms'),
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
        ),
        backgroundColor: const Color(0XFF2F004F),

        body: user == null
            ? const Center(child: Text('You are not logged in.'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('farms')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Check if the user has any farms
                  bool hasFarm =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  // If the user has farms, build the farm list
                  return hasFarm
                      ? _buildFarmList(snapshot.data!.docs)
                      // If the user has no farms, show a message
                      : const Center(
                          child: Text(
                            'No farms added!',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                },
              ),
        floatingActionButton:
            user != null ? _buildFloatingActionButton(context) : null,
        drawer: CustomDrawer(),
      ),
    );
  }

  //this method builds the list of farms when FarmDetailsScreen is called
  Widget _buildFarmList(List<DocumentSnapshot> farmDocs) {
    // Return a ListView.builder widget to display the list of farms
    return ListView.builder(
      itemCount: farmDocs.length,
      itemBuilder: (context, index) {
        // Get the farm data from the document snapshot and cast it to a Map
        var farmData = farmDocs[index].data() as Map<String, dynamic>;
        // Return an InkWell widget for each farm in the list
        return InkWell(
          onTap: () {
            // once the farm is tapped, navigate to the FarmDetailsScreen
            Navigator.of(context).push(
              // and pass the farm ID, farm name, solar panels, rows, and columns
              MaterialPageRoute(
                builder: (context) => FarmDetailsScreen(
                  farmId: farmDocs[index].id,
                  farmName: farmData['farmName'],
                  solarPanels: farmData['solarPanels'],
                  rows: farmData['rows'],
                  columns: farmData['columns'],
                ),
              ),
            );
          },
          //some code for 
          child: ListTile(
            tileColor: const Color(0xFF866B99),
            title: Text(
              farmData['farmName'],
              style: const TextStyle(
                color: Color.fromARGB(255, 54, 43, 62),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete,
                  color: Color.fromARGB(255, 54, 43, 62)),
              onPressed: () =>
                  _deleteConfirmationDialog(context, farmDocs[index].id),
            ),
          ),
        );
      },
    );
  }

  //this method builds the floating action button that allows the user to add a farm
  Widget _buildFloatingActionButton(BuildContext context) {
    // Show a loading indicator while checking for farms
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: CircularProgressIndicator(),
      );
    }

    // If adding is not allowed, return an empty container right away.
    if (!_isAddingAllowed) {
      return Container(); // Hide button if adding is not allowed
    }

    // If adding is allowed, show the button.
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(left: 43, right: 20, bottom: 4),
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to the AddFarmScreen when the button is pressed
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddFarmScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Farm'),
        style: ElevatedButton.styleFrom(
          primary: Colors.deepPurple, // Background color
          onPrimary: Colors.white, // Icon and Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ),
        ),
      ),
    );
  }

   

  Future<void> _deleteConfirmationDialog(
      BuildContext context, String farmId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Farm'),
          content: const Text('Are you sure you want to delete this farm?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteFarm(farmId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

/* ========================================================================== */
/* ========================================================================== */
/**  BIG NOTE --> dear reader, don't delete the below code as it is crucial 
 * and it is the code that we can use to add more than just one farm
 * the above code is just for one .. why? because it is written like this 
 * in the sequence and it will be easier when we fetch data from firestore 
 * for the drone source code to know which farm was inspected we could just 
 * have one */
/* ========================================================================== */
/* ========================================================================== */

// import 'package:flutter/material.dart';
// import 'package:solar_sky_mobile_app/widgets/custom_drawer.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:solar_sky_mobile_app/screens/add_farm_screen.dart';
// import 'package:solar_sky_mobile_app/screens/farm_details_screen.dart';

// class FarmScreen extends StatefulWidget {
//   const FarmScreen({super.key});

//   @override
//   State<FarmScreen> createState() => _FarmScreenState();
// }

// class _FarmScreenState extends State<FarmScreen> {
//   Future<void> _deleteFarm(String farmId) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       try {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .collection('farms')
//             .doc(farmId)
//             .delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Farm deleted successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error deleting farm: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           leadingWidth: 60,
//           centerTitle: true,
//           title: const Text(
//             'Farms',
//           ),
//           automaticallyImplyLeading: false,
//           leading: Builder(
//             builder: (BuildContext context) {
//               return IconButton(
//                 icon: const Icon(Icons.menu),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               );
//             },
//           ),
//         ),
//         backgroundColor: const Color(0XFF2F004F),
//         body: user == null
//             ? const Center(child: Text('You are not logged in.'))
//             : StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(user.uid)
//                     .collection('farms')
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(
//                       child: Text(
//                         'No farms added!',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     );
//                   }

//                   var farms = snapshot.data!.docs;

//                   return ListView.builder(
//                     itemCount: farms.length,
//                     itemBuilder: (context, index) {
//                       var farmData =
//                           farms[index].data() as Map<String, dynamic>;
//                       return InkWell(
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) => FarmDetailsScreen(
//                                 farmId: farms[index].id,
//                                 farmName: farmData['farmName'],
//                                 solarPanels: farmData['solarPanels'],
//                                 rows: farmData['rows'],
//                                 columns: farmData['columns'],
//                               ),
//                             ),
//                           );
//                         },
//                         child: ListTile(
//                           tileColor: const Color(0xFF866B99),
//                           title: Text(
//                             farmData['farmName'],
//                             style: const TextStyle(
//                               color: Color.fromARGB(255, 54, 54, 54),
//                               fontSize: 17,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.delete,
//                                 color: Color(0xFF43364D)),
//                             onPressed: () {
//                               showDialog(
//                                 context: context,
//                                 builder: (BuildContext context) {
//                                   return AlertDialog(
//                                     title: const Text('Delete Farm'),
//                                     content: const Text(
//                                         'Are you sure you want to delete this farm?'),
//                                     actions: <Widget>[
//                                       TextButton(
//                                         child: const Text('Cancel'),
//                                         onPressed: () {
//                                           Navigator.of(context).pop();
//                                         },
//                                       ),
//                                       TextButton(
//                                         child: const Text('Delete'),
//                                         onPressed: () {
//                                           _deleteFarm(farms[index].id);
//                                           Navigator.of(context).pop();
//                                         },
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//         floatingActionButton: user != null
//             ? Container(
//                 alignment: Alignment.bottomCenter,
//                 padding: const EdgeInsets.only(left: 43, right: 20, bottom: 4),
//                 // Wrap the button with a Center widget
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     Navigator.of(context).push(
//                       MaterialPageRoute(
//                           builder: (context) => const AddFarmScreen()),
//                     );
//                   },
//                   icon: const Icon(Icons.add),
//                   label: const Text('Add Farm'),
//                   style: ElevatedButton.styleFrom(
//                     primary: Colors.deepPurple, // Background color
//                     onPrimary: Colors.white, // Icon and Text color

//                     shape: RoundedRectangleBorder(
//                       borderRadius:
//                           BorderRadius.circular(30), // Rounded corners
//                     ),
//                   ),
//                 ),
//               )
//             : null,
//         drawer: CustomDrawer(),
//       ),
//     );
//   }
// }
