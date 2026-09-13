import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/localization/app_locale.dart';
import 'package:flutter_application_1/localization/app_strings.dart';

void main() {
  test(
    'AppLocaleController switches and resets UI locale',
    () {
      final controller =
          AppLocaleController();

      expect(controller.locale, isNull);

      controller.setLanguageCode('ru');

      expect(
        controller.locale?.languageCode,
        'ru',
      );

      controller.setLanguageCode('system');

      expect(controller.locale, isNull);
    },
  );

  test(
    'AppStrings resolves every supported UI language',
    () {
      expect(
        AppStrings.forLanguageCode('zh').words,
        '单词',
      );
      expect(
        AppStrings.forLanguageCode('en').words,
        'Words',
      );
      expect(
        AppStrings.forLanguageCode('ms').words,
        'Perkataan',
      );
      expect(
        AppStrings.forLanguageCode('vi').words,
        'Từ vựng',
      );
      expect(
        AppStrings.forLanguageCode('ru').words,
        'Слова',
      );
    },
  );

  testWidgets(
    'changing app locale updates Localizations.localeOf',
    (tester) async {
      final controller =
          AppLocaleController();

      await tester.pumpWidget(
        AppLocaleScope(
          controller: controller,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return MaterialApp(
                locale: controller.locale,
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
                home: Builder(
                  builder: (context) {
                    return Text(
                      Localizations.localeOf(
                        context,
                      ).languageCode,
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      controller.setLanguageCode('ru');
      await tester.pumpAndSettle();

      expect(find.text('ru'), findsOneWidget);

      controller.setLanguageCode('en');
      await tester.pumpAndSettle();

      expect(find.text('en'), findsOneWidget);
    },
  );
}
