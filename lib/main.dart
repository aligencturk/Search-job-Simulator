import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';

import 'views/setup_view.dart';

void main() {
  runApp(const ProviderScope(child: JobSearchSimulatorApp()));
}

class JobSearchSimulatorApp extends StatelessWidget {
  const JobSearchSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İş Arama Simülatörü - TR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const SetupView(),
    );
  }
}
