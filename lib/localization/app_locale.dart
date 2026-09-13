import 'package:flutter/material.dart';

class AppLocaleController extends ChangeNotifier {
  static const supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
    Locale('ms'),
    Locale('vi'),
    Locale('ru'),
  ];

  Locale? _locale;

  Locale? get locale => _locale;

  String? get languageCode =>
      _locale?.languageCode;

  void setLanguageCode(
    String? languageCode,
  ) {
    final normalized =
        languageCode
            ?.trim()
            .toLowerCase();

    if (normalized == null ||
        normalized.isEmpty ||
        normalized == 'system') {
      _setLocale(null);
      return;
    }

    final supported = supportedLocales.any(
      (locale) =>
          locale.languageCode == normalized,
    );

    if (!supported) {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Unsupported UI language',
      );
    }

    _setLocale(Locale(normalized));
  }

  void _setLocale(Locale? value) {
    if (_locale?.languageCode ==
        value?.languageCode) {
      return;
    }

    _locale = value;
    notifyListeners();
  }
}

class AppLocaleScope
    extends InheritedNotifier<
        AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(
    BuildContext context,
  ) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<
            AppLocaleScope>();

    assert(
      scope != null,
      'AppLocaleScope not found in context.',
    );

    return scope!.notifier!;
  }
}
