import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brisk App'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: ()=> _showTransferDialog(context), child: Text('Book a transfer'),),
              SizedBox(width: 10,),
              ElevatedButton(onPressed: (){}, child: Text('Add a car video')),
            ],
          )
        ]),
      ),
    );
  }
}
void _showTransferDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Select Transfer Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/airport_to_accommodation');
              },
              child: Text('Airport to Accommodation'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/airport_to_accommodation');
              },
              child: Text('Accommodation to Airport'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/other_transfer');
              },
              child: Text('Other Transfers'),
            ),
          ],
        ),
      );
    },
  );
}
