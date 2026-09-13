import 'package:flutter/material.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';

import '../data/added_language_store.dart';
import '../localization/app_locale.dart';
import '../localization/app_strings.dart';
import '../localization/ui_strings.dart';
import '../models/added_language.dart';
import 'country_select.dart';
import 'language_overview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AddedLanguageStore _store = AddedLanguageStore.instance;

  List<AddedLanguage> _items = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _store.load();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openLanguageLibrary() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const CountrySelect(),
      ),
    );

    if (!mounted) return;
    await _loadItems();
  }

  Future<void> _removeItem(AddedLanguage item) async {
    await _store.remove(item);
    if (!mounted) return;
    await _loadItems();
  }

  String get _uiLanguageCode =>
      Localizations.localeOf(context).languageCode;

  int get _countryCount => _items
      .map((item) => item.countryCode.toUpperCase())
      .toSet()
      .length;

  int get _variantCount =>
      _items.where((item) => item.variantCode != null).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadItems,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildTopBar(),
              SliverToBoxAdapter(
                child: _HomeWelcomeBanner(
                  itemCount: _items.length,
                  countryCount: _countryCount,
                  variantCount: _variantCount,
                  onExplorePressed: _openLanguageLibrary,
                ),
              ),
              _buildSectionHeader(),
              _buildContent(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 96),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLanguageLibrary,
        elevation: 3,
        highlightElevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          AppStrings.of(context).addLanguage,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: const Padding(
        padding: EdgeInsets.only(left: 20, right: 8),
        child: Text(
          'Glyphora',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: AppStrings.of(context).addLanguage,
          onPressed: _openLanguageLibrary,
          icon: const Icon(
            Icons.add_circle_outline_rounded,
          ),
        ),
        _buildLanguageMenu(),
        IconButton(
          tooltip: AppStrings.of(context).settings,
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLanguageMenu() {
    final strings = AppStrings.of(context);
    final controller = AppLocaleScope.of(context);
    final selectedLanguageCode = controller.languageCode;

    return PopupMenuButton<String>(
      tooltip: strings.interfaceLanguage,
      icon: const Icon(Icons.language_outlined),
      onSelected: (value) {
        controller.setLanguageCode(
          value == 'system' ? null : value,
        );
      },
      itemBuilder: (context) {
        return [
          CheckedPopupMenuItem<String>(
            value: 'system',
            checked: selectedLanguageCode == null,
            child: Text(strings.followSystem),
          ),
          ...AppLocaleController.supportedLocales.map(
            (locale) {
              final code = locale.languageCode;
              return CheckedPopupMenuItem<String>(
                value: code,
                checked: selectedLanguageCode == code,
                child: Text(strings.languageName(code)),
              );
            },
          ),
        ];
      },
    );
  }

  Widget _buildSectionHeader() {
    final strings = UiStrings.of(context);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.myLanguages,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (_items.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  strings.itemCount(_items.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: 3,
          separatorBuilder: (_, _) =>
              const SizedBox(height: 12),
          itemBuilder: (_, _) =>
              const _LanguageCardSkeleton(),
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: _buildErrorView(),
      );
    }

    if (_items.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptyLanguageView(
          onAddPressed: _openLanguageLibrary,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _LanguageCard(
            key: ValueKey(
              '${item.countryCode}_${item.languageCode}_${item.variantCode}',
            ),
            item: item,
            uiLanguageCode: _uiLanguageCode,
            onTap: _openOverview,
            onRemove: (displayName) {
              _confirmRemove(item, displayName);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    final colors = Theme.of(context).colorScheme;
    final strings = UiStrings.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: colors.error,
          ),
          const SizedBox(height: 12),
          Text(
            strings.failedToLoadData,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.onErrorContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadItems,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: Text(AppStrings.of(context).retry),
          ),
        ],
      ),
    );
  }

  void _openOverview(
    CountryConfig country,
    LanguageConfig language,
    LanguageVariantConfig? variant,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => LanguageOverviewScreen(
          country: country,
          language: language,
          variant: variant,
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    AddedLanguage item,
    String displayName,
  ) async {
    final strings = UiStrings.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(strings.removeLanguage),
          content: Text(
            strings.confirmRemoveLanguage(displayName),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: Text(strings.cancel),
            ),
            FilledButton.tonal(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.error,
              ),
              child: Text(strings.remove),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _removeItem(item);
    }
  }
}

class _HomeWelcomeBanner extends StatelessWidget {
  final int itemCount;
  final int countryCount;
  final int variantCount;
  final VoidCallback onExplorePressed;

  const _HomeWelcomeBanner({
    required this.itemCount,
    required this.countryCount,
    required this.variantCount,
    required this.onExplorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = UiStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer,
              colors.secondaryContainer,
              colors.tertiaryContainer,
            ],
            stops: const [0, 0.52, 1],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.translate_rounded,
                color: colors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.welcomeBack,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              itemCount == 0
                  ? strings.startBuildingLibrary
                  : strings.continueExploring,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colors.onPrimaryContainer
                    .withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatisticChip(
                    value: itemCount.toString(),
                    label: strings.added,
                    accent: colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatisticChip(
                    value: countryCount.toString(),
                    label: strings.countriesRegions,
                    accent: colors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatisticChip(
                    value: variantCount.toString(),
                    label: strings.dialectVariants,
                    accent: colors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onExplorePressed,
              icon: const Icon(
                Icons.explore_outlined,
                size: 18,
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              label: Text(
                itemCount == 0
                    ? strings.exploreLanguageLibrary
                    : strings.addMoreLanguages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticChip extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _StatisticChip({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final AddedLanguage item;
  final String uiLanguageCode;
  final void Function(
    CountryConfig,
    LanguageConfig,
    LanguageVariantConfig?,
  ) onTap;
  final ValueChanged<String> onRemove;

  const _LanguageCard({
    super.key,
    required this.item,
    required this.uiLanguageCode,
    required this.onTap,
    required this.onRemove,
  });

  String _firstCharacter(String value) {
    final text = value.trim();
    if (text.isEmpty) return '?';
    return String.fromCharCode(text.runes.first);
  }

  Color _languageColor(String code) {
    final normalized = code.toLowerCase();
    const palette = [
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
      Colors.purple,
      Colors.blue,
      Colors.pink,
      Colors.green,
      Colors.amber,
    ];

    final index = normalized.codeUnits.fold<int>(
          0,
          (sum, unit) => sum + unit,
        ) %
        palette.length;

    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = UiStrings.of(context);
    final accent = _languageColor(
      item.variantCode ?? item.languageCode,
    );

    final cardColor = Color.alphaBlend(
      accent.withValues(alpha: 0.07),
      colors.surfaceContainerLow,
    );

    final country = CountryConfig.findByCode(item.countryCode);
    final language = LanguageConfig.findByCode(item.languageCode);
    final variant = item.variantCode == null
        ? null
        : LanguageVariantConfig.findByCode(
            item.variantCode!,
          );

    final countryName =
        country?.nameOf(uiLanguageCode) ?? item.countryCode;
    final languageName =
        language?.nameOf(uiLanguageCode) ?? item.languageCode;
    final variantName = variant?.nameOf(uiLanguageCode);

    final title = variantName ?? languageName;
    final subtitle = variantName == null
        ? countryName
        : '$languageName · $countryName';
    final isClickable = country != null && language != null;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isClickable
            ? () => onTap(country, language, variant)
            : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _firstCharacter(title),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _CodeChip(
                          label: item.languageCode.toUpperCase(),
                          accent: accent,
                        ),
                        if (item.variantCode != null) ...[
                          const SizedBox(width: 6),
                          _CodeChip(
                            label: item.variantCode!.toUpperCase(),
                            accent: accent,
                            isSecondary: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove(title);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(strings.removeFromHome),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String label;
  final Color accent;
  final bool isSecondary;

  const _CodeChip({
    required this.label,
    required this.accent,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: isSecondary ? 0.20 : 0.11,
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyLanguageView extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyLanguageView({
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = UiStrings.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primaryContainer
                  .withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.language_rounded,
              size: 32,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.noLanguagesYet,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            strings.noLanguagesYetDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(strings.addFirstLanguage),
          ),
        ],
      ),
    );
  }
}

class _LanguageCardSkeleton extends StatelessWidget {
  const _LanguageCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.4);

    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
