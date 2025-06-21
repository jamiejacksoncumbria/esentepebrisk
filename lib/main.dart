// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:url_strategy/url_strategy.dart';

import 'firebase_options/firebase_options.dart';
import 'models/customer_model.dart';

// screens & settings
import 'screens/customer_search_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/airport_screen.dart';
import 'settings/staff_screen.dart';
import 'settings/car_screen.dart';
import 'transfers_screens/other_transfer.dart';
import 'transfers_screens/airport_to_accommodation.dart';
import 'transfers_screens/accommodation_to_airport.dart';
import 'car_video_screens/car_video_screen.dart';
import 'print_label_screen/print_ticket_screen.dart';  // contains PrintLabelScreen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setPathUrlStrategy();
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    void onSignedIn(BuildContext ctx) {
      Navigator.of(ctx, rootNavigator: true)
          .pushReplacementNamed(CustomerSearchScreen.routeName);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.red,
        colorScheme:
        ColorScheme.fromSwatch(primarySwatch: Colors.red).copyWith(
          secondary: Colors.redAccent,
        ),
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          color: Colors.red,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.red,
          textTheme: ButtonTextTheme.accent,
          disabledColor: Colors.black38,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.white),
        ),
      ),

      initialRoute: FirebaseAuth.instance.currentUser == null
          ? '/sign-in'
          : CustomerSearchScreen.routeName,

      routes: {
        '/sign-in': (ctx) => Scaffold(
          appBar: AppBar(title: const Text('Brisk Login / Signup')),
          body: SignInScreen(
            providers: providers,
            actions: [
              AuthStateChangeAction<UserCreated>((ctx, state) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(ctx, rootNavigator: true)
                      .pushReplacementNamed('/sign-in');
                });
              }),
              AuthStateChangeAction<SignedIn>((ctx, state) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onSignedIn(ctx);
                });
              }),
            ],
          ),
        ),

        '/profile': (ctx) => ProfileScreen(
          appBar: AppBar(title: const Text('Brisk [Edit your profile]')),
          providers: providers,
          actions: [
            SignedOutAction((ctx) {
              Navigator.of(ctx, rootNavigator: true)
                  .pushReplacementNamed('/sign-in');
            }),
          ],
        ),

        '/other_transfer': (_) => const OtherTransfersScreenScreen(),
        '/airport_to_accommodation': (_) =>
        const AirportToAccommodationScreen(),
        '/accommodation_to_airport': (_) =>
        const AccommodationToAirportScreen(),
        CustomerSearchScreen.routeName: (_) => const CustomerSearchScreen(),
        CarVideoScreen.routeName: (_) => const CarVideoScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        AirportScreen.routeName: (_) => const AirportScreen(),
        StaffScreen.routeName: (_) => const StaffScreen(),
        CarScreen.routeName: (_) => const CarScreen(),
        // **NOTE**: we no longer put '/print_label' here
      },

      onGenerateRoute: (settings) {
        if (settings.name == PrintLabelScreen.routeName) {
          final args = settings.arguments;
          if (args is! CustomerModel) {
            throw Exception(
                'PrintLabelScreen requires a CustomerModel argument.'
            );
          }
          return MaterialPageRoute(
            builder: (_) => PrintLabelScreen(customer: args),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}