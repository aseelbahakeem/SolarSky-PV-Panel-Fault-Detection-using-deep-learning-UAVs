import 'package:flutter/material.dart';

/* 
this page is used to display the contact information of the SolarSky App
and the user can contact the SolarSky team through the email, 
PS: the email is real
*/

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFF2F004F),
        title: const Text(
          'Contact Us',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color:
            Colors.white, // Replace with the actual color code from the design
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SolarSky is working on answering all your questions and solving your issues through the email',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromARGB(255, 34, 34, 34),
                fontSize:
                    24, // Replace with the actual font size from the design
              ),
            ),
            SizedBox(height: 24),
            Text(
              'solarskycustomercare@gmail.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromARGB(255, 34, 34, 34),
                fontSize:
                    20, // Replace with the actual font size from the design
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
