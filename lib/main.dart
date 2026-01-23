import 'package:b2c_app/core/router.dart';
import 'package:b2c_app/core/services/event_context_service.dart';
import 'package:b2c_app/features/auth/services/auth_service.dart';
import 'package:b2c_app/features/events/services/event_service.dart';
import 'package:b2c_app/features/visa/services/visa_service.dart';
import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized for async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URL strategy for Flutter Web (enables proper deep links)
  // This ensures URLs like /events/2/hotline are preserved on page refresh
  usePathUrlStrategy();

  // Initialize EventContextService to load saved event/site context
  // This MUST complete before runApp so pages can access site_id synchronously
  await eventContextService.init();

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()..tryAutoLogin()),
          ProxyProvider<AuthService, EventService>(
            update: (context, auth, previous) => EventService(auth),
          ),
          ProxyProvider<AuthService, VisaService>(
            update: (context, auth, previous) => VisaService(auth),
          ),
          // Provide EventContextService for widgets that need to listen to changes
          ChangeNotifierProvider.value(value: eventContextService),
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
