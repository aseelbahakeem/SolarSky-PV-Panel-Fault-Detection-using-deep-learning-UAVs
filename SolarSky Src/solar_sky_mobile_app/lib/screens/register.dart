/*
this class is used to register the user and store the user credentials 
to the firebase authentication
 */
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class Register {
  Future<UserCredential> register(
      String email, String password, File image) async {
    final userCredentials = await _firebase.createUserWithEmailAndPassword(
        email: email, password: password);

    return userCredentials;
  }
}
