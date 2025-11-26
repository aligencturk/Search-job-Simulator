import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: _getTextTheme(),
      ),
      home: const SetupView(),
    );
  }

  TextTheme _getTextTheme() {
    try {
      return GoogleFonts.poppinsTextTheme();
    } catch (e) {
      // Test ortamında veya font yüklenemezse varsayılan tema kullan
      return const TextTheme();
    }
  }
}
