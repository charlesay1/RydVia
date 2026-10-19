import 'package:flutter/material.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';
import 'package:rydvia_models/rydvia_models.dart';
import '../auth_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.auth});
  final AuthController auth;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final phone = TextEditingController();
  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final (subtitle, copy, icon) = switch (auth.role) {
      ProductRole.customer => (
        'Ride. Deliver. Move.',
        'Book rides, send packages, and move with confidence.',
        Icons.route_outlined,
      ),
      ProductRole.driver => (
        'Drive. Earn. Move.',
        'Accept ride and delivery requests, track earnings, and stay connected on the go.',
        Icons.directions_car_outlined,
      ),
      ProductRole.business => (
        'Sell. Manage. Grow.',
        'Receive orders, manage your business, and grow with RydVia’s digital platform.',
        Icons.storefront_outlined,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(RydViaSpacing.s24),
          decoration: BoxDecoration(
            color: RydViaColors.midnightNavy,
            borderRadius: BorderRadius.circular(RydViaRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: RydViaColors.warmCoral,
                size: RydViaSpacing.s48,
              ),
              const SizedBox(height: RydViaSpacing.s24),
              Text(
                subtitle,
                style: RydViaTypography.h1.copyWith(
                  color: RydViaColors.warmOffWhite,
                ),
              ),
              const SizedBox(height: RydViaSpacing.s12),
              Text(
                'Premium mobility. Warm technology. Effortless movement.',
                style: RydViaTypography.body.copyWith(
                  color: RydViaColors.softSlate,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RydViaSpacing.s24),
        Semantics(
          header: true,
          child: Text(
            'Welcome to RydVia',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: RydViaSpacing.s8),
        Text(copy),
        const SizedBox(height: RydViaSpacing.s24),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => auth.sendCode(phone.text),
          decoration: const InputDecoration(
            labelText: 'Enter your mobile number',
            prefixText: '🇬🇭 +233  ',
          ),
        ),
        if (auth.message != null)
          Padding(
            padding: const EdgeInsets.only(top: RydViaSpacing.s12),
            child: Semantics(liveRegion: true, child: Text(auth.message!)),
          ),
        const SizedBox(height: RydViaSpacing.s20),
        RydViaButton(
          label: 'Continue',
          loading: auth.busy,
          onPressed: () => auth.sendCode(phone.text),
        ),
        TextButton(
          onPressed: auth.busy ? null : () => auth.sendCode(phone.text),
          child: const Text('Sign In'),
        ),
        const SizedBox(height: RydViaSpacing.s16),
        Text(
          'By continuing, you agree to RydVia’s Terms & Conditions and Privacy Policy.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Wrap(
          children: [
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/terms'),
              child: const Text('Terms & Conditions'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/privacy'),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
      ],
    );
  }
}
