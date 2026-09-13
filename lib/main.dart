import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_locale.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() =>
      _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLocaleController
      _localeController;

  @override
  void initState() {
    super.initState();
    _localeController =
        AppLocaleController();
  }

  @override
  void dispose() {
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: _localeController,
      child: AnimatedBuilder(
        animation: _localeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Glyphora',
            debugShowCheckedModeBanner:
                false,
            locale:
                _localeController.locale,
            supportedLocales:
                AppLocaleController
                    .supportedLocales,
            localizationsDelegates:
                const [
              GlobalMaterialLocalizations
                  .delegate,
              GlobalWidgetsLocalizations
                  .delegate,
              GlobalCupertinoLocalizations
                  .delegate,
            ],
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(
                seedColor:
                    Colors.deepPurple,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}