import 'package:flutter/material.dart';

import 'onboarding_page.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.child});
  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    isOnboarded().then((v) {
      if (mounted) setState(() => _onboarded = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboarded!) {
      return OnboardingPage(
        onFinished: () => setState(() => _onboarded = true),
      );
    }
    return widget.child;
  }
}
