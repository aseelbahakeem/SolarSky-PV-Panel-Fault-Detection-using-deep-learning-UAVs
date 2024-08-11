/*this screen is used as a loading screen whilst Firebase figuring our 
weather we have a token or not and if we do have a token then we will be 
redirected to the chat screen and if we don't have a token then we will 
be redirected to the welcome screen*/

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SolarSky'),
      ),
      body: const Center(
        child: Text('Loading...'),
      ),
    );
  }
}


