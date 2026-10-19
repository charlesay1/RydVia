import 'package:flutter/material.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';
import '../auth_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.auth});
  final AuthController auth;
  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final name = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Complete your profile',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: RydViaSpacing.s20),
      RydViaTextField(label: 'Your name', controller: name),
      if (widget.auth.message != null) Text(widget.auth.message!),
      const SizedBox(height: RydViaSpacing.s20),
      RydViaButton(
        label: 'Continue',
        loading: widget.auth.busy,
        onPressed: () => widget.auth.onboard(name.text),
      ),
      TextButton(
        onPressed: widget.auth.busy ? null : widget.auth.signOut,
        child: const Text('Sign out'),
      ),
    ],
  );
}
