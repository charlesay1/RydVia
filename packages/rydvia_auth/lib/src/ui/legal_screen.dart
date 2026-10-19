import 'package:flutter/material.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(RydViaSpacing.s20),
        child: Text(
          'Final legal text has not been supplied. This build is not ready for public onboarding.',
        ),
      ),
    ),
  );
}
