import 'package:flutter/material.dart';

import 'core/theme/warm_theme.dart';
import 'features/shell/home_shell.dart';

class PeriodCalendarApp extends StatelessWidget {
  const PeriodCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Period Calendar',
      debugShowCheckedModeBanner: false,
      theme: WarmTheme.light(),
      darkTheme: WarmTheme.dark(),
      home: const HomeShell(),
    );
  }
}
