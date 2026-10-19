import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';
import 'package:rydvia_core/rydvia_core.dart';
import '../auth_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.auth});
  final AuthController auth;
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final code = TextEditingController();
  late final Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final remaining = (auth.resendAt?.difference(DateTime.now()).inSeconds ?? 0)
        .clamp(0, auth.config.resendSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Enter Code', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: RydViaSpacing.s12),
        Text('We sent a verification code to ${auth.phone ?? ''}'),
        const SizedBox(height: RydViaSpacing.s24),
        TextField(
          controller: code,
          autofocus: true,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(auth.config.otpLength),
          ],
          maxLength: auth.config.otpLength,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: '${auth.config.otpLength}-digit verification code',
          ),
          onChanged: (value) {
            if (validOtp(value, auth.config.otpLength))
              unawaited(auth.verify(value));
          },
          onSubmitted: auth.verify,
        ),
        if (auth.message != null)
          Semantics(liveRegion: true, child: Text(auth.message!)),
        const SizedBox(height: RydViaSpacing.s20),
        RydViaButton(
          label: 'Continue',
          loading: auth.busy,
          onPressed: () => auth.verify(code.text),
        ),
        const SizedBox(height: RydViaSpacing.s16),
        const Text("Didn't receive a code?"),
        TextButton(
          onPressed: remaining > 0 || auth.busy
              ? null
              : () {
                  code.clear();
                  auth.sendCode(auth.phone!);
                },
          child: Text(
            remaining > 0 ? 'Resend code in ${remaining}s' : 'Resend code',
          ),
        ),
        TextButton(
          onPressed: auth.busy ? null : auth.editPhone,
          child: const Text('Change mobile number'),
        ),
      ],
    );
  }
}
