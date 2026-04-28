import 'package:flutter/material.dart';

class PortalScreen extends StatelessWidget {
  const PortalScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Portal: $token')),
    );
  }
}
