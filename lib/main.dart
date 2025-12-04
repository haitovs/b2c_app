import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router.dart';

void main() {
  runApp(const B2CApp());
}

class B2CApp extends StatelessWidget {
  const B2CApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'B2C App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3C4494)),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        // Locale('ru'), // Russian (Future)
        // Locale('tk'), // Turkmen (Future)
      ],
    );
  }
}
