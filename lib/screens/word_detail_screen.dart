import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/lang_schema_service.dart';
import '../localization/app_strings.dart';
import '../models/lang_schema.dart';
import '../models/word_entry.dart';

class WordDetailScreen
    extends StatelessWidget {
  final String languageCode;
  final WordEntry entry;

  const WordDetailScreen({
    super.key,
    required this.languageCode,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          entry.word.isEmpty
              ? AppStrings.of(context)
                  .entryDetails
              : entry.word,
        ),
      ),
      body: entry.isCanonical
          ? _buildCanonicalBody(context)
          : _buildLegacyBody(context),
    );
  }

  Widget _buildLegacyBody(
    BuildContext context,
  ) {
    return FutureBuilder<
        DictionaryTypeSchema?>(
      future: LangSchemaService.instance
          .getTypeSchema(
        languageCode: languageCode,
        tableName: entry.tableName,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildError(
            snapshot.error,
          );
        }

        return _buildLegacyContent(
          context,
          snapshot.data,
        );
      },
    );
  }

  Widget _buildCanonicalBody(
    BuildContext context,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context),
        if (entry.senses.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCanonicalSenses(
            context,
          ),
        ],
        if (entry.matchedForms
            .isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildMatchedForms(
            context,
          ),
        ],
        if (entry.allForms.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFullParadigm(
            context,
          ),
        ],
        const SizedBox(height: 16),
        _buildCanonicalMetadata(
          context,
        ),
      ],
    );
  }

  Widget _buildCanonicalSenses(
    BuildContext context,
  ) {
    final strings =
        AppStrings.of(context);

    return _buildCard(
      context,
      title: strings.senses,
      children: entry.senses.map(
        (sense) {
          final glosses =
              sense.glosses.isEmpty
                  ? strings.noGloss
                  : sense.glosses.join(' / ');

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  strings.senseNumber(
                    sense.number,
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  glosses,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(growable: false),
    );
  }

  Widget _buildMatchedForms(
    BuildContext context,
  ) {
    final strings =
        AppStrings.of(context);
    final searchedForms = entry.matchedForms
        .map((analysis) => analysis.form)
        .where((form) => form.trim().isNotEmpty)
        .toSet()
        .join(' / ');

    return _buildCard(
      context,
      title: strings.searchMatches,
      children: [
        if (searchedForms.isNotEmpty) ...[
          Text(
            strings.searchedFor(
              searchedForms,
            ),
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
          const SizedBox(height: 6),
        ],
        Text(
          strings.lemmaValue(
            entry.word,
          ),
          style: Theme.of(context)
              .textTheme
              .bodyLarge,
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        ...entry.matchedForms.map(
          (analysis) => _buildAnalysis(
            context,
            analysis,
          ),
        ),
      ],
    );
  }

  Widget _buildFullParadigm(
    BuildContext context,
  ) {
    final strings =
        AppStrings.of(context);
    final groups = _groupAllForms(
      entry.allForms,
    );

    final groupNames = _orderedGroupNames(
      entry.type,
      groups.keys,
    );

    return _buildCard(
      context,
      title: strings.fullParadigm(
        entry.allForms.length,
      ),
      children: groupNames
          .map(
            (groupName) => ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding:
                  const EdgeInsets.only(
                bottom: 8,
              ),
              title: Text(
                strings.morphologyGroupLabel(
                  groupName,
                ),
              ),
              subtitle: Text(
                strings.formsCount(
                  groups[groupName]!.length,
                ),
              ),
              children: groups[groupName]!
                  .map(
                    (analysis) =>
                        _buildParadigmRow(
                      context,
                      analysis,
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, List<MorphologyAnalysis>>
      _groupAllForms(
    List<MorphologyAnalysis> forms,
  ) {
    final groups =
        <String, List<MorphologyAnalysis>>{};

    for (final analysis in forms) {
      final group =
          _paradigmGroupName(analysis);

      groups
          .putIfAbsent(
            group,
            () => <MorphologyAnalysis>[],
          )
          .add(analysis);
    }

    return groups;
  }

  List<String> _orderedGroupNames(
    String partOfSpeech,
    Iterable<String> existingGroups,
  ) {
    final existing =
        existingGroups.toSet();

    final preferred =
        partOfSpeech == 'noun'
            ? const [
                'singular',
                'plural',
                'possessive',
                'case',
                'interrogative',
                'special',
              ]
            : const [
                'infinitive',
                'past',
                'present',
                'future',
                'person',
                'negative',
              ];

    return [
      ...preferred.where(existing.contains),
      ...existing.where(
        (name) => !preferred.contains(name),
      ),
    ];
  }

  String _paradigmGroupName(
    MorphologyAnalysis analysis,
  ) {
    if (analysis.partOfSpeech == 'noun') {
      if (_featureBool(
        analysis.features['special'],
      )) {
        return 'special';
      }

      if (_featureBool(
        analysis.features['interrogative'],
      )) {
        return 'interrogative';
      }

      final possessive = _featureText(
        analysis.features['possessive'],
      );

      if (possessive.isNotEmpty &&
          possessive != 'none') {
        return 'possessive';
      }

      final caseName = _featureText(
        analysis.features['case'],
      );

      if (caseName.isNotEmpty &&
          caseName != 'nominative') {
        return 'case';
      }

      if (_featureText(
            analysis.features['number'],
          ) ==
          'pl') {
        return 'plural';
      }

      return 'singular';
    }

    if (analysis.partOfSpeech == 'verb') {
      if (_featureText(
            analysis.features['form_type'],
          ) ==
          'infinitive') {
        return 'infinitive';
      }

      if (_featureBool(
        analysis.features['negative'],
      )) {
        return 'negative';
      }

      switch (_featureText(
        analysis.features['tense'],
      )) {
        case 'past':
          return 'past';
        case 'present':
          return 'present';
        case 'future':
          return 'future';
      }

      if (_featureText(
        analysis.features['person'],
      ).isNotEmpty) {
        return 'person';
      }
    }

    return 'other';
  }

  Widget _buildParadigmRow(
    BuildContext context,
    MorphologyAnalysis analysis,
  ) {
    final summary =
        _analysisSummary(
      context,
      analysis,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SelectableText(
            analysis.form,
            style: Theme.of(context)
                .textTheme
                .titleSmall,
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(summary),
          ],
          const SizedBox(height: 3),
          Text(
            analysis.canonicalKey,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  String _analysisSummary(
    BuildContext context,
    MorphologyAnalysis analysis,
  ) {
    final keys =
        analysis.partOfSpeech == 'noun'
            ? const [
                'number',
                'possessive',
                'case',
                'interrogative',
                'special',
              ]
            : const [
                'form_type',
                'tense',
                'person',
                'negative',
              ];

    final parts = <String>[];

    for (final key in keys) {
      final value =
          analysis.features[key];

      if (value is bool) {
        if (value) {
          parts.add(
            _featureLabel(
              context,
              key,
            ),
          );
        }
        continue;
      }

      if (!_hasValue(value)) {
        continue;
      }

      parts.add(
        _featureValue(
          context,
          key,
          value,
        ),
      );
    }

    return parts.join(' · ');
  }

  bool _featureBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value
        ?.toString()
        .trim()
        .toLowerCase();

    return normalized == '1' ||
        normalized == 'true';
  }

  String _featureText(dynamic value) {
    return value
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
  }

  Widget _buildAnalysis(
    BuildContext context,
    MorphologyAnalysis analysis,
  ) {
    final visibleFeatures =
        analysis.features.entries
            .where(
              (item) => _hasValue(
                item.value,
              ),
            )
            .toList(growable: false);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerLowest,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SelectableText(
            analysis.form,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            analysis.canonicalKey,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
          if (visibleFeatures
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            ...visibleFeatures.map(
              (item) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        _featureLabel(
                          context,
                          item.key,
                        ),
                        style:
                            Theme.of(context)
                                .textTheme
                                .labelMedium,
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        _featureValue(
                          context,
                          item.key,
                          item.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCanonicalMetadata(
    BuildContext context,
  ) {
    final strings =
        AppStrings.of(context);
    final rows = <MapEntry<String, String>>[
      MapEntry(
        strings.partOfSpeech,
        _partOfSpeechLabel(
          context,
          entry.type,
        ),
      ),
      if (entry.languageCode != null)
        MapEntry(
          strings.language,
          entry.languageCode!,
        ),
      if (entry.lexemeId != null)
        MapEntry(
          'Lexeme ID',
          entry.lexemeId!,
        ),
      MapEntry(
        strings.generatedForms,
        '${entry.formCount}',
      ),
      if (entry.matchTypes.isNotEmpty)
        MapEntry(
          strings.matchMethod,
          entry.matchTypes
              .map(
                (value) => _matchLabel(
                  context,
                  value,
                ),
              )
              .join(' / '),
        ),
    ];

    return _buildCard(
      context,
      title: strings.entryInformation,
      children: rows
          .map(
            (row) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      row.key,
                      style:
                          Theme.of(context)
                              .textTheme
                              .labelMedium,
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      row.value,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLegacyContent(
    BuildContext context,
    DictionaryTypeSchema? schema,
  ) {
    final visibleSections =
        _visibleSections(schema);

    final usedKeys = <String>{
      for (final section in visibleSections)
        ...section.keys,
    };

    final extraKeys = entry.details.keys
        .where(
          (key) =>
              !usedKeys.contains(key) &&
              _hasValue(
                entry.details[key],
              ),
        )
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        if (visibleSections.isEmpty)
          _buildFallbackSection(context)
        else
          ...visibleSections.map(
            (section) =>
                _buildSchemaSection(
              context,
              section,
            ),
          ),
        if (extraKeys.isNotEmpty)
          _buildValuesSection(
            context,
            title: '其他信息',
            keys: extraKeys,
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    final meta = <String>[
      if (!entry.isCanonical &&
          _isUseful(entry.sheetName))
        entry.sheetName,
      if (_isUseful(entry.type))
        entry.isCanonical
            ? _partOfSpeechLabel(
                context,
                entry.type,
              )
            : entry.type,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            entry.word.isEmpty
                ? AppStrings.of(context)
                    .unnamedEntry
                : entry.word,
            style: Theme.of(context)
                .textTheme
                .headlineMedium,
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(meta.join(' · ')),
          ],
          if (_isUseful(
            entry.meanings,
          )) ...[
            const SizedBox(height: 14),
            Text(
              entry.meanings,
              style: const TextStyle(
                fontSize: 17,
                height: 1.45,
              ),
            ),
          ],
          if (entry.isCanonical &&
              entry.primaryMatch != null) ...[
            const SizedBox(height: 10),
            Text(
              _matchLabel(
                context,
                entry.primaryMatch!,
              ),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge,
            ),
          ],
        ],
      ),
    );
  }

  List<DictionarySectionSchema>
      _visibleSections(
    DictionaryTypeSchema? schema,
  ) {
    if (schema == null) {
      return const [];
    }

    return schema.sections
        .where(
          (section) =>
              section.keys.any(
            (key) => _hasValue(
              entry.details[key],
            ),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildSchemaSection(
    BuildContext context,
    DictionarySectionSchema section,
  ) {
    return _buildValuesSection(
      context,
      title: section.title ??
          entry.sheetName,
      keys: section.keys,
    );
  }

  Widget _buildFallbackSection(
    BuildContext context,
  ) {
    final keys = entry.details.keys
        .where(
          (key) => _hasValue(
            entry.details[key],
          ),
        )
        .toList(growable: false);

    if (keys.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '这个词条没有可显示的详细字段',
          ),
        ),
      );
    }

    return _buildValuesSection(
      context,
      title: entry.sheetName.isEmpty
          ? '详细信息'
          : entry.sheetName,
      keys: keys,
    );
  }

  Widget _buildValuesSection(
    BuildContext context, {
    required String title,
    required List<String> keys,
  }) {
    final visibleKeys = keys
        .where(
          (key) => _hasValue(
            entry.details[key],
          ),
        )
        .toList(growable: false);

    if (visibleKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant,
          ),
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 12),
            ...visibleKeys.map(
              (key) => _buildValueRow(
                context,
                key,
                entry.details[key],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow(
    BuildContext context,
    String key,
    dynamic value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: Theme.of(context)
                .textTheme
                .labelLarge,
          ),
          const SizedBox(height: 4),
          SelectableText(
            _displayValue(value),
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '读取语言 Schema 失败\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  bool _hasValue(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is String) {
      final text =
          value.trim().toLowerCase();

      return text.isNotEmpty &&
          text != 'nan' &&
          text != 'null';
    }

    if (value is Iterable) {
      return value.isNotEmpty;
    }

    if (value is Map) {
      return value.isNotEmpty;
    }

    return true;
  }

  String _displayValue(dynamic value) {
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(value);
    }

    return value.toString();
  }

  String _partOfSpeechLabel(
    BuildContext context,
    String value,
  ) {
    return AppStrings.of(context)
        .partOfSpeechLabel(value);
  }

  String _matchLabel(
    BuildContext context,
    String value,
  ) {
    return AppStrings.of(context)
        .matchTypeLabel(value);
  }

  String _featureLabel(
    BuildContext context,
    String key,
  ) {
    return AppStrings.of(context)
        .featureLabel(key);
  }

  String _featureValue(
    BuildContext context,
    String key,
    dynamic value,
  ) {
    return AppStrings.of(context)
        .featureValue(
      key,
      value,
    );
  }

  bool _isUseful(String value) {
    final normalized =
        value.trim().toLowerCase();

    return normalized.isNotEmpty &&
        normalized != '未知' &&
        normalized != '未命名' &&
        normalized != 'nan' &&
        normalized != 'null';
  }
}
