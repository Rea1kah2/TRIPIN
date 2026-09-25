import 'package:flutter/material.dart';

class DetailRencanaScreen extends StatelessWidget {
  final String rencanaId;

  const DetailRencanaScreen({super.key, required this.rencanaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Detail Rencana: $rencanaId')),
    );
  }
}
