import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


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

    return MaterialApp(
      title: 'Esentepe Brisk',
      debugShowCheckedModeBanner: false,

      theme: appTheme,
      home: const MyHomePage(title: 'Esentepe Brisk'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text('A Text', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        child: const Icon(Icons.add),
      ),
    );
  }
}
