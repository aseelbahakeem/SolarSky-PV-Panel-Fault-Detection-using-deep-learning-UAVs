import 'package:flutter/material.dart';
import 'package:solar_sky_mobile_app/screens/change_password_screen.dart';
import 'package:solar_sky_mobile_app/screens/contact_us.dart';
import 'package:solar_sky_mobile_app/screens/delete_account_screen.dart';

/*
this is the settings screen of the app which contains the settings options
to change password and contact us and the logic to navigate to the 
change password and contact us screens
 */
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0XFF2F004F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Contact Us'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ContactUsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete Account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to the change password screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DeleteAccountScreen(),
                  ),
                );
              },
            ),
          ],
        ).toList(),
      ),
    );
  }
}
