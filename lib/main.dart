// lib/main.dart

import 'package:Brisk_Auto_Rent_A_Car_And_Garage/settings/child_seat_screen.dart';
import 'package:Brisk_Auto_Rent_A_Car_And_Garage/settings/driver_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdb;
import 'package:url_strategy/url_strategy.dart';

import 'firebase_options/firebase_options.dart';
import 'models/customer_model.dart';

// screens & settings
import 'screens/customer_search_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/airport_screen.dart';
import 'settings/staff_screen.dart';
import 'settings/car_screen.dart';
// **Transfers**
import 'transfers_screens/other_transfer.dart';
import 'transfers_screens/airport_to_accommodation.dart';
import 'transfers_screens/accommodation_to_airport.dart';
// **Car video**
import 'car_video_screens/car_video_screen.dart';
// **Print label**
import 'print_label_screen/print_ticket_screen.dart';
// **By‐date carousel**
import 'screens/car_videos_by_date_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setPathUrlStrategy();
  tzdb.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Nicosia'));

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
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red)
            .copyWith(secondary: Colors.redAccent),
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

        // core screens
        CustomerSearchScreen.routeName: (_) => const CustomerSearchScreen(),
        SettingsScreen.routeName: (_)     => const SettingsScreen(),
        ChildSeatScreen.routeName: (_)   => const ChildSeatScreen(),
        AirportScreen.routeName: (_)     => const AirportScreen(),
        StaffScreen.routeName: (_)       => const StaffScreen(),
        DriverScreen.routeName: (_)      => const DriverScreen(),
        CarVideosByDateScreen.routeName: (_) => const CarVideosByDateScreen(),
        CarScreen.routeName: (_)         => const CarScreen(),

        // Other Transfers (no args)
        '/other_transfer': (_) => const OtherTransfersScreenScreen(),

        // Car Video needs customerId
        CarVideoScreen.routeName: (ctx) {
          final custId = ModalRoute.of(ctx)!.settings.arguments as String;
          return CarVideoScreen(customerId: custId);
        },
      },

      // now handle all the transfer screens & print label via onGenerateRoute
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AirportToAccommodationScreen.routeName:
            final customer = settings.arguments as CustomerModel;
            return MaterialPageRoute(
              builder: (_) => AirportToAccommodationScreen(customer: customer),
            );

          case AccommodationToAirportScreen.routeName:
          // <— accept just the CustomerModel, same as above
            final customer = settings.arguments as CustomerModel;
            return MaterialPageRoute(
              builder: (_) => AccommodationToAirportScreen(customer: customer),
            );

          case PrintLabelScreen.routeName:
            final customer = settings.arguments as CustomerModel;
            return MaterialPageRoute(
              builder: (_) => PrintLabelScreen(customer: customer),
            );

          default:
            return null;
        }
      },
    );
  }
}
