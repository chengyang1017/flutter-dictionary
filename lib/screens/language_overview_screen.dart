import 'package:flutter/material.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';

import 'word_list_screen.dart';

import '../data/added_language_store.dart';
import '../models/added_language.dart';

class LanguageOverviewScreen
    extends StatelessWidget {
  final CountryConfig country;
  final LanguageConfig language;
  final LanguageVariantConfig? variant;

  const LanguageOverviewScreen({
    super.key,
    required this.country,
    required this.language,
    this.variant,
  });

  String _uiLanguageCode(
    BuildContext context,
  ) {
    return Localizations.localeOf(context)
        .languageCode;
  }

  String _displayName(
    String uiLanguageCode,
  ) {
    return variant?.nameOf(
          uiLanguageCode,
        ) ??
        language.nameOf(
          uiLanguageCode,
        );
  }

  String _breadcrumb(
    String uiLanguageCode,
  ) {
    final countryName =
        country.nameOf(uiLanguageCode);

    final languageName =
        language.nameOf(uiLanguageCode);

    final variantName =
        variant?.nameOf(uiLanguageCode);

    if (variantName == null) {
      return '$countryName  >  $languageName';
    }

    return '$countryName  >  '
        '$languageName  >  $variantName';
  }

  @override
  Widget build(BuildContext context) {
    final uiLanguageCode =
        _uiLanguageCode(context);

    return Scaffold(
      appBar: AppBar(
  title: Text(
    _breadcrumb(uiLanguageCode),
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  ),
  actions: [
    IconButton(
      tooltip: '加入首页',
      icon: const Icon(
        Icons.add_circle_outline,
      ),
      onPressed: () async {
        final added =
            await AddedLanguageStore.instance.add(
          AddedLanguage(
            countryCode: country.code,
            languageCode: language.code,
            variantCode: variant?.code,
          ),
        );

        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              added
                  ? '已经加入首页'
                  : '首页中已经存在',
            ),
          ),
        );
      },
    ),
  ],
),
      body: SafeArea(
        child: _buildBody(
          context,
          uiLanguageCode,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    String uiLanguageCode,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverviewCard(
            context,
            uiLanguageCode,
          ),
          const SizedBox(height: 16),
          _buildModuleGrid(
            context,
            uiLanguageCode,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    String uiLanguageCode,
  ) {
    final languageName =
        _displayName(uiLanguageCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        '$languageName 的语言资料入口。\n\n'
        '点击下面的模块查看字母表、词条、'
        '词缀规则、语法说明、日常短语和词形分析。',
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildModuleGrid(
    BuildContext context,
    String uiLanguageCode,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: _modules.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        return _buildModuleTile(
          context,
          _modules[index],
          uiLanguageCode,
        );
      },
    );
  }

  Widget _buildModuleTile(
    BuildContext context,
    LanguageModule module,
    String uiLanguageCode,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(14),
      onTap: () {
        _openModule(
          context,
          module,
          uiLanguageCode,
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                module.icon,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            module.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openModule(
    BuildContext context,
    LanguageModule module,
    String uiLanguageCode,
  ) {
    if (module.type ==
        LanguageModuleType.words) {
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) {
            return WordListScreen(
              language: language,
              variant: variant,
            );
          },
        ),
      );

      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return LanguageModuleScreen(
            module: module,
            languageName:
                _displayName(
              uiLanguageCode,
            ),
          );
        },
      ),
    );
  }

  static const List<LanguageModule>
      _modules = [
    LanguageModule(
      type: LanguageModuleType.alphabet,
      title: '字母表',
      icon: Icons.abc,
    ),
    LanguageModule(
      type: LanguageModuleType.words,
      title: '单词',
      icon: Icons.menu_book_outlined,
    ),
    LanguageModule(
      type: LanguageModuleType.affixes,
      title: '词缀规则',
      icon: Icons.account_tree_outlined,
    ),
    LanguageModule(
      type: LanguageModuleType.grammar,
      title: '语法说明',
      icon: Icons.subject,
    ),
    LanguageModule(
      type: LanguageModuleType.phrases,
      title: '日常短语',
      icon: Icons.chat_bubble_outline,
    ),
    LanguageModule(
      type: LanguageModuleType.morphology,
      title: '词形分析',
      icon: Icons.schema_outlined,
    ),
  ];
}

enum LanguageModuleType {
  alphabet,
  words,
  affixes,
  grammar,
  phrases,
  morphology,
}

class LanguageModule {
  final LanguageModuleType type;
  final String title;
  final IconData icon;

  const LanguageModule({
    required this.type,
    required this.title,
    required this.icon,
  });
}

class LanguageModuleScreen
    extends StatelessWidget {
  final LanguageModule module;
  final String languageName;

  const LanguageModuleScreen({
    super.key,
    required this.module,
    required this.languageName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$languageName · ${module.title}',
        ),
      ),
      body: Center(
        child: Text(
          '$languageName\n${module.title}',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall,
        ),
      ),
    );
  }
}
