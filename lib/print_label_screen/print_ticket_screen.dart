import 'package:flutter/material.dart';

class PrintLabelScreen extends StatefulWidget {
  const PrintLabelScreen({super.key});

  @override
  State<PrintLabelScreen> createState() => _PrintLabelScreenState();
}

class _PrintLabelScreenState extends State<PrintLabelScreen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(appBar: AppBar(title: Text('Brisky Ticket Print Screen'),),);
  }
}
