import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solar_sky_mobile_app/widgets/custom_drawer.dart';
import 'package:solar_sky_mobile_app/screens/add_drone_screen.dart';
/*
 * this page is used to display the drones added by the user 
 * and also to add a new drone to the user's account
 */
class DroneScreen extends StatefulWidget {
  const DroneScreen({Key? key}) : super(key: key);

  @override
  _DroneScreenState createState() => _DroneScreenState();
}

class _DroneScreenState extends State<DroneScreen> {
  void _addDrone() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddDroneScreen(),
      ),
    );
  }

  Future<void> _deleteDrone(String droneId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('drones')
            .doc(droneId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Drone deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting drone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDroneForInspection(String droneId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get all drones and mark the selected one, unmark others
      final dronesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('drones')
          .get();

      for (var drone in dronesSnapshot.docs) {
        bool isSelected = drone.id == droneId;
        await drone.reference.update({'isSelected': isSelected});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Drones'),
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
        body: Column(
          children: [
            Expanded(
              child: user == null
                  ? const Center(child: Text('You are not logged in.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('drones')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No drones added!',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        var drones = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: drones.length,
                          itemBuilder: (context, index) {
                            var droneData =
                                drones[index].data() as Map<String, dynamic>;
                            bool isSelected = droneData['isSelected'] ?? false;

                            return ListTile(
                              // Add the check mark icon on the left if the drone is selected
                              leading: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: Color.fromARGB(255, 28, 78, 10))
                                  : null,
                              tileColor: const Color(0xFF866B99),
                              title: Text(
                                droneData['name'],
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 54, 43, 62),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () async {
                                if (!isSelected) {
                                  // Show dialog only if the drone is not already selected
                                  String droneName = droneData['name'] ?? '';
                                  bool confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Select Drone'),
                                            content: Text(
                                              'Do you want to select "$droneName" for your next inspection?',
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('No'),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(false);
                                                },
                                              ),
                                              TextButton(
                                                child: const Text('Yes'),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(true);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ) ??
                                      false;

                                  if (confirm) {
                                    _selectDroneForInspection(drones[index].id);
                                  }
                                }
                              },

                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Color.fromARGB(255, 54, 43, 62)),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Delete Drone'),
                                        content: const Text(
                                            'Are you sure you want to delete this drone?'),
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
                                              _deleteDrone(drones[index].id);
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
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0, left: 50.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Center row contents horizontally
                children: [
                  ElevatedButton.icon(
                    onPressed: _addDrone,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Drone'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.deepPurple, // Background color
                      onPrimary: Colors.white, // Icon and Text color
                    ),
                  ),
                  const SizedBox(width: 10), // Space between buttons
                  IconButton(
                    icon: Container(
                      decoration: const BoxDecoration(
                        color: Colors
                            .deepPurple, // Set your desired background color
                        shape: BoxShape.circle,

                        // Make the container circular
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(
                            8.0), // Adjust padding to fit the icon size
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                    ),
                    onPressed: () {
                      // Show dialog or snackbar with the explanation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Important: Select a Drone'),
                            content: const Text(
                                'It is important to select a drone for your inspections. To do that:\n'
                                ' - Tap on a drone in the list to select it for your next inspection.\n'
                                ' - A selected drone is marked with a check icon and will be used to track '
                                'which drone conducted each inspection.'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        drawer: CustomDrawer(),
        backgroundColor: const Color(0XFF2F004F),
      ),
    );
  }
}
