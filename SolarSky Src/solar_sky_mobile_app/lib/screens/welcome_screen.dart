// welcome_screen.dart
import 'package:flutter/material.dart';

/*
this class is used to display the welcome screen of the app
where the user can navigate to login or create an account
 */
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  // final double width;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0XFF2F004F),
        body: SingleChildScrollView(
          // Allows the screen to be scrollable
          child: Container(
            width: MediaQuery.of(context)
                .size
                .width, // Adjusts to the screen width
            padding: const EdgeInsets.symmetric(horizontal: 21),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0XFF2F004F), Color(0XFF2F004F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 110),
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    "Welcome to ",
                    style: TextStyle(
                        color: Color(0XFF8588A3),
                        fontSize: 43,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600),
                  ),
                ),

                Align(
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: const Offset(-31, 0),
                    child: Image.asset('assets/images/solarsky.png'),
                  ),
                ),
                const SizedBox(
                  height: 320,
                ),
                // Spacer removed since SingleChildScrollView will handle the layout
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 50.0), // Reduced bottom padding
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                // Added padding to compensate for the keyboard
                Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
