import 'package:flutter/material.dart';

class GolfEdgeApp extends StatelessWidget {
  const GolfEdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Edge',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(
          child: Text('Golf Edge Tablet UI'),
        ),
      ),
    );
  }
}
