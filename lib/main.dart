import 'package:b2c_app/core/router.dart';
import 'package:b2c_app/features/auth/services/auth_service.dart';
import 'package:b2c_app/features/events/services/event_service.dart';
import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:provider/provider.dart';

void main() {
  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()..tryAutoLogin()),
          ProxyProvider<AuthService, EventService>(
            update: (context, auth, previous) => EventService(auth),
          ),
        ],
        child: const B2CApp(),
      ),
    ),
  );
}

class B2CApp extends StatefulWidget {
  const B2CApp({super.key});

  @override
  State<B2CApp> createState() => _B2CAppState();
}

class _B2CAppState extends State<B2CApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize router only once
    _router ??= createRouter(context.read<AuthService>());
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return const SizedBox.shrink(); // Should never happen
    }
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'B2C App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3C4494)),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: _router!,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    );
  }
}
