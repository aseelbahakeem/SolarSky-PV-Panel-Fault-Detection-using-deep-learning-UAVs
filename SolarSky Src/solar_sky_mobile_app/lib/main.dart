import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_sky_mobile_app/screens/splash.dart';
import 'package:solar_sky_mobile_app/screens/home.dart';
import 'package:solar_sky_mobile_app/screens/welcome_screen.dart';
import 'package:solar_sky_mobile_app/screens/login_screen.dart';
import 'package:solar_sky_mobile_app/screens/register_screen.dart';
import 'package:solar_sky_mobile_app/screens/farm_screen.dart';

/*
this file is the entry point of the app which contains the main method
to run the app and the MyApp class which is the root widget of the app
and contains the MaterialApp widget to define the app's theme and routes
where the app navigates to the home screen if the user is authenticated
or to the welcome screen if the user is not authenticated
and from there the user can navigate to the login or register screen 
and so on so forth
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, //to remove debug banner from the app on the top right corner
      title: 'SolarSky',
      theme: ThemeData().copyWith(
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const WelcomeScreen();
        },
      ),
      routes: {
        '/chat': (ctx) => const HomeScreen(),
        '/welcome': (ctx) => const WelcomeScreen(),
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/FarmScreen': (ctx) => const FarmScreen(),
      },
    );
  }
}
