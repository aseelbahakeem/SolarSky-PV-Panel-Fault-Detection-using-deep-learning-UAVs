import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StartInspectionTimer extends StatefulWidget {
  @override
  _StartInspectionTimerState createState() => _StartInspectionTimerState();
}

class _StartInspectionTimerState extends State<StartInspectionTimer> {
  bool isInspectionActive = false;
  Stopwatch stopwatch = Stopwatch();
  String inspectionTime = "00:00";
  bool hasFarm = false; // Flag to check farm existence
  bool hasSelectedDrone = false; // Flag to check drone selection

  @override
  void initState() {
    super.initState();
    checkUserHasFarm();
    checkDroneSelected();
    listenToInspectionStatus();
  }

  Future<void> checkDroneSelected() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var droneSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('drones')
          .where('isSelected', isEqualTo: true)
          .limit(1)
          .get();
      setState(() {
        hasSelectedDrone = droneSnapshot.docs.isNotEmpty;
      });
    }
  }

  Future<void> checkUserHasFarm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var farmSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('farms')
          .limit(1)
          .get();
      setState(() {
        hasFarm =
            farmSnapshot.docs.isNotEmpty; // Set hasFarm based on farm existence
      });
    }
  }

  void listenToInspectionStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          final isActive = data['StartInspectionTimer'] ?? false;

          if (isInspectionActive && !isActive) {
            // If the inspection just finished (StartInspectionTimer changed from true to false)
            saveInspectionTime();
          }

          setState(() {
            isInspectionActive = isActive;
            if (isInspectionActive) {
              stopwatch.start();
            } else {
              stopwatch.stop();
            }
          });
        }
      });
    }
  }

// Save the inspection time when the inspection finishes
  void saveInspectionTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Format the elapsed time and save it to Firestore
      String elapsedTime = formatTime(stopwatch.elapsedMilliseconds);
      await userDocRef.update({'InspectionTime': elapsedTime});

      setState(() {});

      stopwatch.reset(); // Reset the stopwatch for the next inspection
    }
  }

  String formatTime(int milliseconds) {
    var secs = milliseconds ~/ 1000;
    var minutes = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
    var seconds = (secs % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void confirmStartInspection() async {
    await checkUserHasFarm();
    await checkDroneSelected();

    if (!hasFarm || !hasSelectedDrone) {
      String errorMessage = !hasFarm
          ? 'Please add a farm before starting an inspection.'
          : 'Please select a drone before starting an inspection.';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Requirement Missing'),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    // Show confirmation dialog if farm exists and drone is selected
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Inspection'),
          content: Text(
            'Are you ready to start the inspection? Make sure the drone is set up and ready to fly. The inspection cannot be stopped once started and must be completed through the drone control system.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Start'),
              onPressed: () {
                Navigator.of(context).pop();
                startInspection(); // Proceed with starting the inspection
              },
            ),
          ],
        );
      },
    );
  }

  void startInspection() async {
    // Re-check to ensure a farm exists when the inspection starts
    if (!hasFarm) {
      return; // Exit if no farm exists
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      stopwatch.reset();
      stopwatch.start();
      await userDocRef.update({'StartInspectionTimer': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF2F004F),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          title: const Text('Inspection'),
          centerTitle: true,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Inspection Timer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 50),
            StreamBuilder<int>(
              stream: Stream.periodic(Duration(seconds: 1), (i) {
                return stopwatch.elapsedMilliseconds;
              }),
              builder: (context, snapshot) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    // Apply a white border and a transparent fill to the circle
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                    color: const Color(0XFF2F004F), // The background color fill
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isInspectionActive
                        ? formatTime(snapshot.data ?? 0)
                        : inspectionTime,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            isInspectionActive
                ? const Text(
                    'Inspection is ongoing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                : ElevatedButton(
                    onPressed: confirmStartInspection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      primary: const Color(0xFF008955),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text(
                      'Start Inspection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
