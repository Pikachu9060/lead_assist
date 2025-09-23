
import 'package:flutter/material.dart';

class CustomFloatingActionButton extends StatelessWidget{
  final Widget navigationPage;
  final String buttonName;
  const CustomFloatingActionButton({super.key, required this.navigationPage, required this.buttonName});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FloatingActionButton.extended(
      onPressed: () => {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => navigationPage),
        )
      },
      icon: const Icon(Icons.add),
      label: Text(buttonName),
      backgroundColor: Colors.deepPurple,
    );
  }
}