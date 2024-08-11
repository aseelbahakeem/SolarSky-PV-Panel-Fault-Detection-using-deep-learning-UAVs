import 'package:flutter/material.dart';
import 'package:solar_sky_mobile_app/screens/login_logout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_sky_mobile_app/screens/home.dart';

/*
this is the login screen of the app which contains the login form
 and the logic to authenticate the use,
navigate to the home screen upon successful login,
display the error message upon unsuccessful login,
display the loading spinner while authenticating the user,
toggle the password visibility,
to validate the form fields,
and to save the form fields
 */
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  var _userEmail = '';
  var _userPassword = '';
  var _isAuthenticating = false;
  final LoginLogout _loginLogout = LoginLogout();
// This function will be used to toggle password visibility
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

// This function will be used to submit the form and authenticate the user
  _submit() async {
    // Validate the form fields before submitting the form
    final isValid = _form.currentState!.validate();
    // If the form is not valid, return from the function
    if (!isValid) {
      return;
    }
    // Save the form fields if the form is valid
    if (isValid) {
      _form.currentState!.save();
      // Try to authenticate the user with the provided email and password
      try {
        // Set the isAuthenticating state to true to show the loading spinner
        setState(() {
          _isAuthenticating = true;
        });
        // Call the login method of the LoginLogout class and pass the email and password as parameters
        final userCredentials =
            await _loginLogout.login(_userEmail, _userPassword);
        // Navigate to the home screen upon successful login
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()));
        // Catch any FirebaseAuthException and display the error message
      } on FirebaseAuthException catch (error) {
        var errorMessage = 'An error occurred, please check your credentials!';
        // If the error message is not null
        if (error.message != null) {
          // Set the error message to the error message returned by FirebaseAuth
          errorMessage = error.message!;
        }
        // Show the error message in a snackbar
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Set the content of the snackbar to the error message
            content: Text(error.message ??
                'An error occurred! Please check your credentials.'),
          ),
        );
        // Set the isAuthenticating state to false to hide the loading spinner
      } finally {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper function to trigger a password reset email
    void _resetPassword() async {
      String email = ''; // Variable to store user input
      // Show a dialog for the user to enter their email address
      await showDialog(
        context: context,
        // Use an AlertDialog to show the dialog
        builder: (context) => AlertDialog(
          title: Text('Reset Password'),
          content: TextField(
            // Use a TextField to allow the user to enter their email address
            onChanged: (value) => email = value,
            decoration: InputDecoration(labelText: 'Email Address'),
          ),
          // Add two buttons to the dialog
          actions: [
            TextButton(
              child: Text('Cancel'),
              // Close the dialog when the user presses the Cancel button
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Reset'),
              onPressed: () async {
                // Check if the email is not empty and contains an '@' symbol
                if (email.isNotEmpty && email.contains('@')) {
                  try {
                    // Send a password reset email to the user
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    Navigator.of(context).pop(); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Password reset email sent! Check your inbox.')));
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.message}')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Please enter a valid email address.')));
                }
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0XFF2F004F), // Deep purple background color
      appBar: AppBar(
        backgroundColor: Colors.transparent, // No AppBar, set to transparent
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Removed Container, use Text directly with proper styling
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Text(
                    "Sign in with your email address",
                    textAlign: TextAlign.left, // Center align text
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28, // Adjust font size as per design
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 50), // Add space between text and fields
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: const TextStyle(color: Colors.white70),
                    // Define an outline border with rounded corners
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1), // White border for enabled state
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1.5), // White, bold border for enabled state
                    ),
                    // Define the border for when the TextFormField is being interacted with (focused)
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1), // White border for focused state
                    ),
                    // Background color fill
                    filled: true,
                    fillColor: const Color(
                        0xFF341A59), // The fill color for the TextFormField
                    // Placeholder text with lighter white color
                    hintText: 'Email Address',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _userEmail = value!;
                  },
                ),
                const SizedBox(height: 35), // Add space between the fields
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      // Changed to OutlineInputBorder to have uniform borders
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.white, width: 2), // Bold white border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2), // Bold white border for enabled state
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2), // Bold white border for focused state
                    ),
                    filled: true,
                    fillColor: const Color(
                        0xFF341A59), // The fill color for the TextFormField
                    suffixIcon: IconButton(
                      icon: Icon(
                        // Based on passwordVisible state choose the icon
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors
                            .white70, // Adjusted to white70 to match the labelStyle
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    // Rest of the decoration as per design
                  ),
                  obscureText: !_passwordVisible,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must be at least 8 characters long.';
                    }
                    // String pattern =
                    //     r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%]).{8,}$';
                    // RegExp regex = RegExp(pattern);
                    // if (value == null ||
                    //     value.isEmpty ||
                    //     !regex.hasMatch(value)) {
                    //   return 'Password must be at least 8 characters long,\n include an uppercase letter, a lowercase letter, a number,\n and a special character.';
                    // }
                    return null;
                  },
                  onSaved: (value) {
                    _userPassword = value!;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    onPressed: _resetPassword,
                  ),
                ),
                const SizedBox(height: 270), // Add space before the button
                if (_isAuthenticating) const CircularProgressIndicator(),
                if (!_isAuthenticating)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: const Color(
                          0xFF008955), // Set the button color to #008955
                      minimumSize: const Size(double.infinity, 59),
                      shape: RoundedRectangleBorder(
                        // Shape property to customize the button's border
                        borderRadius: BorderRadius.circular(
                            9), // Rounded corners with a radius of 12
                      ),

                      // Set the button size
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Sign in', // Text should be 'Sign Up' as per the design
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
