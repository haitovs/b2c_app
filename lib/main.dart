import 'package:b2c_app/core/router/app_router.dart';
import 'package:b2c_app/core/services/event_context_service.dart';
import 'package:b2c_app/core/theme/app_theme.dart';
import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/shared_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URL strategy for Flutter Web (enables proper deep links)
  usePathUrlStrategy();

  // Pre-load SharedPreferences so it can be injected synchronously
  final prefs = await SharedPreferences.getInstance();

  // Initialize EventContextService to load saved event/site context
  await eventContextService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const B2CApp(),
    ),
  );
}

class B2CApp extends ConsumerWidget {
  const B2CApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'B2C App',
      theme: AppTheme.theme,
      routerConfig: router,
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
