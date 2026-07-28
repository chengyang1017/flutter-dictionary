import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/country_languages_select.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';

class CountrySelect extends StatefulWidget {
  const CountrySelect({
    super.key,
    this.onSelected,
    this.initialCountryCode,
  });

  final ValueChanged<CountryConfig>? onSelected;
  final String? initialCountryCode;

  @override
  State<CountrySelect> createState() =>
      _CountrySelectState();
}

class _CountrySelectState extends State<CountrySelect> {
  String _keyword = '';

  String get _uiLanguageCode {
    return Localizations.maybeLocaleOf(context)
            ?.languageCode ??
        'zh';
  }

  List<CountryConfig> get _filteredCountries {
    final countries = CountryConfig.sortedBy(
      _uiLanguageCode,
    );

    if (_keyword.isEmpty) {
      return countries;
    }

    return countries.where((country) {
      return country.matches(_keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择国家'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchField(),
            Expanded(
              child: _buildCountryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _keyword = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText: '搜索国家',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryList() {
    final countries = _filteredCountries;

    if (countries.isEmpty) {
      return const Center(
        child: Text('没有找到这个国家'),
      );
    }

    return ListView.builder(
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];

        return _buildCountryTile(country);
      },
    );
  }

  Widget _buildCountryTile(
    CountryConfig country,
  ) {
    final isSelected =
        widget.initialCountryCode?.toUpperCase() ==
            country.code.toUpperCase();

    return ListTile(
      leading: Text(
        country.flag,
        style: const TextStyle(
          fontSize: 40,
        ),
      ),
      title: Text(
        country.nameOf(_uiLanguageCode),
      ),
      subtitle: Text(
        country.code,
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            )
          : null,
      onTap: () async {
        final language =
            await Navigator.push<LanguageConfig>(
          context,
          MaterialPageRoute(
            builder: (context) {
              return CountryLanguagesSelect(
                country: country,
              );
            },
          ),
        );

        if (!context.mounted ||
            language == null) {
          return;
        }

        Navigator.pop(
          context,
          language,
        );
      },
    );
  }
}