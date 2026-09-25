import 'package:flutter/material.dart';

class DetailDestinasiScreen extends StatelessWidget {
  final String destinasiId;

  const DetailDestinasiScreen({super.key, required this.destinasiId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Detail Destinasi: $destinasiId')),
    );
  }
}
