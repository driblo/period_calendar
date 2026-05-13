import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/warm_palette.dart';
import '../security/pin_setup_page.dart';

const _kOnboardedKey = 'onboarded_v1';

Future<bool> isOnboarded() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardedKey) ?? false;
}

Future<void> setOnboarded() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardedKey, true);
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.spa_outlined,
      title: 'Welcome',
      body: 'A warm, private place to track your cycle.',
    ),
    _Slide(
      icon: Icons.calendar_month,
      title: 'Log easily',
      body: 'Mark period days, mood, flow, and symptoms with a single tap.',
    ),
    _Slide(
      icon: Icons.lock_outline,
      title: 'Yours alone',
      body: 'Your data stays on this device. Add a PIN to lock the app.',
    ),
  ];

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await setOnboarded();
    if (!mounted) return;
    final goPin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set a PIN now?'),
        content: const Text(
          'You can always do this later in Settings → Privacy & security.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (goPin == true) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinSetupPage()),
      );
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == _index
                          ? WarmPalette.clay
                          : Theme.of(context).colorScheme.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _index == _slides.length - 1 ? 'Get started' : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(slide.icon, size: 96, color: WarmPalette.clay),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
