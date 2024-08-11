import 'package:firebase_auth/firebase_auth.dart';

/*
this class is used to login and logout the user
 */

// create an instance of FirebaseAuth 
final _firebase = FirebaseAuth.instance;

//
class LoginLogout {

  // login method that takes email and password as parameters and returns a UserCredential  
  Future<UserCredential> login(String email, String password) async {
    // call the signInWithEmailAndPassword method of FirebaseAuth and pass the email and password
    final userCredentials = await _firebase.signInWithEmailAndPassword(
        email: email, password: password);
        // return the userCredentials 
    return userCredentials;
  }

  Future<void> logout() async {
    await _firebase.signOut();
  }
}