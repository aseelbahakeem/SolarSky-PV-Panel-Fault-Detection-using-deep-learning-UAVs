import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solar_sky_mobile_app/widgets/custom_drawer_header.dart';
import 'package:solar_sky_mobile_app/screens/settings_screen.dart';
import 'package:solar_sky_mobile_app/screens/help_and_support.dart';

/* 
this widget is used to display the custom drawer in the app
it is used to display the user's profile picture, name, and email
and in addition to that it also contains the settings, help and support,
 and logout options where the user can navigate to the selected screens
*/
class CustomDrawer extends StatefulWidget {
  CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final User? user = FirebaseAuth.instance.currentUser;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color.fromARGB(255, 255, 255, 255),
        child: ListView(
          children: <Widget>[
            FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('users').doc(user?.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  Map<String, dynamic> data =
                      snapshot.data?.data() as Map<String, dynamic>;
                  return CustomDrawerHeader(
                    accountName: "${data['firstName']} ${data['lastName']}",
                    accountEmail: user?.email ?? '',
                    accountImageUrl: data['image_url'],
                  );
                
                } else if (snapshot.hasError) {
                  return const Text("Error loading data");
                }
                return const CircularProgressIndicator();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Navigator.pop(context);
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_outlined),
              title: const Text('Help and Support'),
              onTap: () {
                // Navigator.pop(context);
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => HelpAndSupportScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app,
                  color: Color.fromARGB(255, 41, 41, 41)),
              title: const Text('Logout',
                  style: TextStyle(color: Color.fromARGB(255, 41, 41, 41))),
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/welcome');
              },
            ),
          ],
        ),
      ),
    );
  }
}
