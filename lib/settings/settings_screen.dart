// lib/settings/settings_screen.dart
import 'package:Brisk_Auto_Rent_A_Car_And_Garage/settings/driver_screen.dart';
import 'package:flutter/material.dart';

import '../screens/car_videos_by_date_screen.dart';
import 'child_seat_screen.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings_screen';  // ← add here
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.flight_takeoff),
              label: const Text('Add / Edit Airports'),
              onPressed: () {
                Navigator.pushNamed(context, '/airport');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add / Edit Staff'),
              onPressed: () {
                Navigator.pushNamed(context, '/staff');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions_car),
              label: const Text('Add / Edit Cars'),
              onPressed: () {
                Navigator.pushNamed(context, '/car');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.event_seat),
              label: const Text('Add / Edit Child Seat'),
              onPressed: () {
                Navigator.pushNamed(context, ChildSeatScreen.routeName);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.drive_eta),
              label: const Text('Add / Edit Drivers'),
              onPressed: () {
                Navigator.pushNamed(context, DriverScreen.routeName);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('View Car Videos'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CarVideosByDateScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
