import 'package:flutter/material.dart';

class CarVideoScreen extends StatelessWidget {
  static const routeName = '/car_video';  // ← add this
  const CarVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Record a car video'),),);
  }
}
