import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const Login());
}



class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData appTheme = ThemeData(
      // Define the primary color
      primaryColor: Colors.red,

      // Define the accent color (now called colorScheme.secondary)
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.red,
      ).copyWith(
        secondary: Colors.redAccent,
      ),

      // Define the brightness (light or dark)
      brightness: Brightness.light,

      // Define other theme properties as needed
      // For example, button theme, text theme, etc.
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.red,
        textTheme: ButtonTextTheme.primary,
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(color: Colors.white), // Example for AppBar title
      ),

      appBarTheme: AppBarTheme(
          color: Colors.red,
          centerTitle: true,
          foregroundColor: Colors.white

      ),
    );
    final providers = [EmailAuthProvider()];

    void onSignedIn() {
      //Navigator.pushReplacementNamed(context, '/profile');
      Navigator.pushReplacementNamed(context, '/home');

    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/profile',
      theme: appTheme,
      routes: {
        '/sign-in': (context) {
          return Scaffold(
            appBar: AppBar(title: Text('Brisk Login / Signup'),),
            body: SignInScreen(
              providers: providers,
              actions: [
                AuthStateChangeAction<UserCreated>((context, state) {
                  // Put any new user logic here
                  Navigator.pushReplacementNamed(context, '/sign-in');                }),
                AuthStateChangeAction<SignedIn>((context, state) {
                  onSignedIn();
                }),
              ],
            ),
          );
        },
        '/profile': (context) {
          return ProfileScreen(
            providers: providers,
            actions: [
              SignedOutAction((context) {
                Navigator.pushReplacementNamed(context, '/sign-in');
              }),
            ],
          );
        },
        '/home': (context) {
          return const Home();
        },
      },
    );
  }
}
