import 'package:flutter/material.dart';

/*
this widget is used to create a custom drawer header
 it is used to display the user's name, email and profile picture
 in the drawer
 */
class CustomDrawerHeader extends StatelessWidget {
  final String accountName;
  final String accountEmail;
  final String accountImageUrl;

  const CustomDrawerHeader({
    Key? key,
    required this.accountName,
    required this.accountEmail,
    required this.accountImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // Increase the height to fit the larger avatar
      child: DrawerHeader(
        decoration: const BoxDecoration(
          color: Color.fromARGB(
              255, 255, 255, 255), // Background color for the Drawer Header
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(accountImageUrl),
              radius: 60, // Increased radius
            ),
            const SizedBox(height: 20), // Space between the avatar and the name
            Text(
              accountName,
              style: const TextStyle(
                color: Colors.black, // Text color
                fontSize: 20, // Font size for account name
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4), // Space between the name and the email
            Text(
              accountEmail,
              style: TextStyle(
                color: Colors.black
                    .withOpacity(0.6), // Text color with some transparency
                fontSize: 14, // Font size for account email
              ),
            ),
          ],
        ),
      ),
    );
  }
}
