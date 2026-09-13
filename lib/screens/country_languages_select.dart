import 'package:flutter/material.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';

import '../localization/ui_strings.dart';
import 'language_overview_screen.dart';

class CountryLanguagesSelect extends StatelessWidget {
  final CountryConfig country;

  const CountryLanguagesSelect({
    super.key,
    required this.country,
  });

  String _uiLanguageCode(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final uiLanguageCode = _uiLanguageCode(context);
    final strings = UiStrings.of(context);
    final countryLanguages = country.countryLanguages;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.countryLanguages(
            country.nameOf(uiLanguageCode),
          ),
        ),
      ),
      body: _buildBody(
        context,
        countryLanguages,
        uiLanguageCode,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<CountryLanguageConfig> countryLanguages,
    String uiLanguageCode,
  ) {
    if (countryLanguages.isEmpty) {
      return Center(
        child: Text(
          UiStrings.of(context).noCountryLanguageData,
        ),
      );
    }

    return ListView.builder(
      itemCount: countryLanguages.length,
      itemBuilder: (context, index) {
        return _buildLanguageTile(
          context,
          countryLanguages[index],
          uiLanguageCode,
        );
      },
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    CountryLanguageConfig relation,
    String uiLanguageCode,
  ) {
    final strings = UiStrings.of(context);
    final language = relation.language;

    if (language == null) {
      return ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(relation.languageCode),
        subtitle: Text(strings.languageDataMissing),
      );
    }

    final variants = relation.variants;

    if (variants.isEmpty) {
      return ListTile(
        leading: _buildFlag(language),
        title: Text(
          language.nameOf(uiLanguageCode),
        ),
        subtitle: Text(language.code),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _openLanguage(context, language);
        },
      );
    }

    return ExpansionTile(
      leading: _buildFlag(language),
      title: Text(
        language.nameOf(uiLanguageCode),
      ),
      subtitle: Text(strings.selectLanguageOrDialect),
      children: _buildVariantTiles(
        context,
        relation,
        language,
        uiLanguageCode,
      ),
    );
  }

  Widget _buildFlag(LanguageConfig language) {
    return Text(
      language.flag,
      style: const TextStyle(fontSize: 32),
    );
  }

  List<Widget> _buildVariantTiles(
    BuildContext context,
    CountryLanguageConfig relation,
    LanguageConfig language,
    String uiLanguageCode,
  ) {
    final strings = UiStrings.of(context);
    final variants = relation.variants;

    return [
      if (relation.allowDirectSelection)
        ListTile(
          contentPadding: const EdgeInsets.only(
            left: 72,
            right: 16,
          ),
          title: Text(
            strings.allLanguage(
              language.nameOf(uiLanguageCode),
            ),
          ),
          subtitle: Text(language.code),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _openLanguage(context, language);
          },
        ),
      ...variants.map(
        (variant) {
          return ListTile(
            contentPadding: const EdgeInsets.only(
              left: 72,
              right: 16,
            ),
            title: Text(
              variant.nameOf(uiLanguageCode),
            ),
            subtitle: Text(variant.code),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openLanguage(
                context,
                language,
                variant: variant,
              );
            },
          );
        },
      ),
    ];
  }

  void _openLanguage(
    BuildContext context,
    LanguageConfig language, {
    LanguageVariantConfig? variant,
  }) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return LanguageOverviewScreen(
            country: country,
            language: language,
            variant: variant,
          );
        },
      ),
    );
  }
}
