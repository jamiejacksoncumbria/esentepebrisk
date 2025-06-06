import 'package:Brisk_Auto_Rent_A_Car_And_Garage/screens/customer_search_screen.dart';
import 'package:Brisk_Auto_Rent_A_Car_And_Garage/transfers_screens/accommodation_to_airport.dart';
import 'package:Brisk_Auto_Rent_A_Car_And_Garage/transfers_screens/airport_to_accommodation.dart';
import 'package:Brisk_Auto_Rent_A_Car_And_Garage/transfers_screens/other_transfer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: const Login()));
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData appTheme = ThemeData(
      primaryColor: Colors.red,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.red,
      ).copyWith(
        secondary: Colors.redAccent,
      ),
      brightness: Brightness.light,
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.red,
        textTheme: ButtonTextTheme.accent,
        disabledColor: Colors.black38,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white),
      ),
      appBarTheme: const AppBarTheme(
        color: Colors.red,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
    );

    final providers = [EmailAuthProvider()];

    void onSignedIn(BuildContext context) {
      Navigator.of(context, rootNavigator: true).pushReplacementNamed('/customer_form');
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute:
      FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/customer_form',
      routes: {
        '/sign-in': (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Brisk Login / Signup')),
            body: SignInScreen(
              providers: providers,
              actions: [
                AuthStateChangeAction<UserCreated>((context, state) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context, rootNavigator: true)
                        .pushReplacementNamed('/sign-in');
                  });
                }),
                AuthStateChangeAction<SignedIn>((context, state) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onSignedIn(context);
                  });
                }),
              ],
            ),
          );
        },
        '/profile': (context) {
          return ProfileScreen(
            appBar: AppBar(title: Text('Brisk [Edit your profile]'),),
            providers: providers,
            actions: [
              SignedOutAction((context) {
                Navigator.of(context, rootNavigator: true)
                    .pushReplacementNamed('/sign-in');
              }),
            ],
          );
        },
        //'/home': (context) => const Home(),
        '/other_transfer': (context) => const OtherTransfersScreenScreen(),
        '/airport_to_accommodation': (context) => const AirportToAccommodationScreen(),
        '/accommodation_to_airport': (context) => const AccommodationToAirportScreen(),
        '/customer_form': (context) => const CustomerSearchScreen(),

      },
    );
  }
}
