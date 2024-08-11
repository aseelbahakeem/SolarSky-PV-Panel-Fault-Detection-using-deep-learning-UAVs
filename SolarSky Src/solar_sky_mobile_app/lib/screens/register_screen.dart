import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solar_sky_mobile_app/widgets/user_image_picker.dart';
import 'package:solar_sky_mobile_app/screens/home.dart';
import 'package:solar_sky_mobile_app/screens/register.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/* 
this is the registration screen of the app which contains the registration form
  and the logic to register the user,
  navigate to the home screen upon successful registration,
  display the error message upon unsuccessful registration,
  display the loading spinner while registering the user,
  to validate the form fields,
  and to save the form fields, and to pick an image 
*/
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  var _userEmail = '';
  var _userPassword = '';
  var _firstName = '';
  var _lastName = '';
  File? _userImageFile;
  var _isLoading = false;
  final Register _register = Register();

  // this method is used to submit the form and register the user
  _submit() async {
    // Validate the form fields
    final isValid = _form.currentState!.validate();
    FocusScope.of(context).unfocus();

    // Check if the user image is not picked
    if (!isValid || _userImageFile == null) {
      // if not picked, show a snackbar with an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please make sure to fill all fields and pick an image.'),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
      return;
    }
    // Save the form fields
    _form.currentState!.save();
    // Set the loading spinner to true if the form is valid
    setState(() {
      _isLoading = true;
    });

    try {
      // it will create a new user with the email and password provided
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _userEmail,
        password: _userPassword,
      );
      // it will create a reference to the storage location where the image will be stored
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${userCredential.user!.uid}.jpg');
      await storageRef.putFile(_userImageFile!);
      final imageURL = await storageRef.getDownloadURL();
      print(imageURL);

      // it will create a new document in the users collection with the user's data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'firstName': _firstName,
        'lastName': _lastName,
        'email': _userEmail,
        'image_url': imageURL,
        'StartInspectionTimer': false, // Initially set to false
        'InspectionTime': '', // Initially set to an empty string
      });
      // Navigate to another screen after successful registration
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const HomeScreen(), // replace with your screen
      ));
      // Handle the error if the registration fails
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An unexpected error occurred.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    } finally {
      // Set the loading spinner to false after the registration is complete
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFF2F004F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Register',
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'inter',
              fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0XFF2F004F),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    "Sign up with your email address",
                    textAlign: TextAlign.left, // Center align text
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28, // Adjust font size as per design
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  UserImagePicker(
                    onPickImage: (pickedImage) {
                      _userImageFile = pickedImage;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: const TextStyle(color: Colors.white70),
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1), // White border for focused state
                      ),
                      filled: true,
                      fillColor: const Color(0xFF341A59),
                      hintText: 'First Name',
                      hintStyle: const TextStyle(color: Colors.white24),
                    ),
                    style: const TextStyle(
                      color: Colors.white, // Set the color to white
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your first name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _firstName = value!;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: const TextStyle(color: Colors.white70),
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1), // White border for focused state
                      ),
                      filled: true,
                      fillColor: const Color(0xFF341A59),
                      hintText: 'Last Name',
                      hintStyle: const TextStyle(color: Colors.white24),
                    ),
                    style: const TextStyle(
                      color: Colors.white, // Set the color to white
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your last name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _lastName = value!;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Colors.white70),
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
                      hintStyle: const TextStyle(color: Colors.white24),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    style: const TextStyle(
                      // Add this line
                      color: Colors.white, // Set the color to white
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _userEmail = value!;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      // labelText: 'Password',
                      // labelStyle: TextStyle(
                      //   // Add this line
                      //   color: Colors.white,
                      //   fontFamily: 'inter', // Set the color to white
                      // ),
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
                      fillColor: const Color(0xFF341A59),
                    ),
                    obscureText: true,
                    style: const TextStyle(
                      // Add this line
                      color: Colors.white, // Set the color to white
                    ),
                    validator: (value) {
                      // if (value == null ||
                      //     value.trim().isEmpty ||
                      //     value.length < 8) {
                      //   return 'Password must be at least 8 characters long.';
                      // }
                      String pattern =
                          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%]).{8,}$';
                      RegExp regex = RegExp(pattern);
                      if (value == null ||
                          value.isEmpty ||
                          !regex.hasMatch(value)) {
                        return 'Password must be at least 8 characters long,\n include an uppercase letter, a lowercase letter, a number,\n and a special character.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _userPassword = value!;
                    },
                  ),
                  const SizedBox(height: 80), // Add space before the button

                  if (_isLoading) const CircularProgressIndicator(),
                  if (!_isLoading)
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
                        'Sign Up', // Text should be 'Sign Up' as per the design
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
      ),
    );
  }
}
