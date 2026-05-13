import 'package:flutter/material.dart';

import '../../core/widgets/warm_card.dart';
import '../reminders/reminders_settings_page.dart';
import '../security/security_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WarmCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RemindersSettingsPage(),
              ),
            ),
            child: const _Row(
              icon: Icons.notifications_outlined,
              title: 'Reminders',
              subtitle: 'Notifications for period, logging, pills',
            ),
          ),
          const SizedBox(height: 12),
          WarmCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SecuritySettingsPage(),
              ),
            ),
            child: const _Row(
              icon: Icons.lock_outline,
              title: 'Privacy & security',
              subtitle: 'PIN, biometric, export, delete data',
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}
