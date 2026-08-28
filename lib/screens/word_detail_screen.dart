import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/lang_schema_service.dart';
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
              ? '词条详情'
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
    return _buildCard(
      context,
      title: '义项',
      children: entry.senses.map(
        (sense) {
          final glosses =
              sense.glosses.isEmpty
                  ? '暂无释义'
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
                  '义项 ${sense.number}',
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
    final searchedForms = entry.matchedForms
        .map((analysis) => analysis.form)
        .where((form) => form.trim().isNotEmpty)
        .toSet()
        .join(' / ');

    return _buildCard(
      context,
      title: '搜索命中',
      children: [
        if (searchedForms.isNotEmpty) ...[
          Text(
            '你搜索：$searchedForms',
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
          const SizedBox(height: 6),
        ],
        Text(
          '原形：${entry.word}',
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
    final groups = _groupAllForms(
      entry.allForms,
    );

    final groupNames = _orderedGroupNames(
      entry.type,
      groups.keys,
    );

    return _buildCard(
      context,
      title:
          '完整词形变化 · ${entry.allForms.length}',
      children: groupNames
          .map(
            (groupName) => ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding:
                  const EdgeInsets.only(
                bottom: 8,
              ),
              title: Text(groupName),
              subtitle: Text(
                '${groups[groupName]!.length} 个词形',
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
                '单数',
                '复数',
                '所属',
                '格',
                '疑问',
                '特殊形',
              ]
            : const [
                '不定式',
                '过去时',
                '现在时',
                '将来时',
                '人称',
                '否定',
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
        return '特殊形';
      }

      if (_featureBool(
        analysis.features['interrogative'],
      )) {
        return '疑问';
      }

      final possessive = _featureText(
        analysis.features['possessive'],
      );

      if (possessive.isNotEmpty &&
          possessive != 'none') {
        return '所属';
      }

      final caseName = _featureText(
        analysis.features['case'],
      );

      if (caseName.isNotEmpty &&
          caseName != 'nominative') {
        return '格';
      }

      if (_featureText(
            analysis.features['number'],
          ) ==
          'pl') {
        return '复数';
      }

      return '单数';
    }

    if (analysis.partOfSpeech == 'verb') {
      if (_featureText(
            analysis.features['form_type'],
          ) ==
          'infinitive') {
        return '不定式';
      }

      if (_featureBool(
        analysis.features['negative'],
      )) {
        return '否定';
      }

      switch (_featureText(
        analysis.features['tense'],
      )) {
        case 'past':
          return '过去时';
        case 'present':
          return '现在时';
        case 'future':
          return '将来时';
      }

      if (_featureText(
        analysis.features['person'],
      ).isNotEmpty) {
        return '人称';
      }
    }

    return '其他';
  }

  Widget _buildParadigmRow(
    BuildContext context,
    MorphologyAnalysis analysis,
  ) {
    final summary =
        _analysisSummary(analysis);

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
            _featureLabel(key),
          );
        }
        continue;
      }

      if (!_hasValue(value)) {
        continue;
      }

      parts.add(
        _featureValue(
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
    final rows = <MapEntry<String, String>>[
      MapEntry(
        '词类',
        _partOfSpeechLabel(entry.type),
      ),
      if (entry.languageCode != null)
        MapEntry(
          '语言',
          entry.languageCode!,
        ),
      if (entry.lexemeId != null)
        MapEntry(
          'Lexeme ID',
          entry.lexemeId!,
        ),
      MapEntry(
        '已生成词形',
        '${entry.formCount}',
      ),
      if (entry.matchTypes.isNotEmpty)
        MapEntry(
          '命中方式',
          entry.matchTypes
              .map(_matchLabel)
              .join(' / '),
        ),
    ];

    return _buildCard(
      context,
      title: '词条信息',
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
                ? '未命名词条'
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
    String value,
  ) {
    switch (value) {
      case 'noun':
        return '名词';
      case 'verb':
        return '动词';
      default:
        return value;
    }
  }

  String _matchLabel(
    String value,
  ) {
    switch (value) {
      case 'lemma':
        return '原形命中';
      case 'form':
        return '词形命中';
      case 'gloss':
        return '释义命中';
      default:
        return value;
    }
  }

  String _featureLabel(
    String key,
  ) {
    switch (key) {
      case 'form_type':
        return '形态类型';
      case 'tense':
        return '时态';
      case 'person':
        return '人称';
      case 'negative':
        return '否定';
      case 'number':
        return '数';
      case 'possessive':
        return '所属';
      case 'case':
        return '格';
      case 'interrogative':
        return '疑问';
      case 'special':
        return '特殊形';
      default:
        return key;
    }
  }

  String _featureValue(
    String key,
    dynamic value,
  ) {
    if (value is bool) {
      return value ? '是' : '否';
    }

    final text = value?.toString() ?? '';

    if (key == 'tense') {
      switch (text) {
        case 'past':
          return '过去时';
        case 'present':
          return '现在时';
        case 'future':
          return '将来时';
      }
    }

    if (key == 'person') {
      switch (text) {
        case '1sg':
          return '第一人称单数';
        case '2sg':
          return '第二人称单数';
        case '3sg':
          return '第三人称单数';
        case '1pl':
          return '第一人称复数';
        case '2pl':
          return '第二人称复数';
        case '3pl':
          return '第三人称复数';
      }
    }

    if (key == 'number') {
      switch (text) {
        case 'sg':
          return '单数';
        case 'pl':
          return '复数';
      }
    }

    if (key == 'case') {
      switch (text) {
        case 'nominative':
          return '主格';
        case 'genitive':
          return '领属格';
        case 'dative':
          return '向格';
        case 'accusative':
          return '宾格';
        case 'locative':
          return '位格';
        case 'ablative':
          return '从格';
        case 'instrumental':
          return '工具格';
      }
    }

    if (key == 'form_type') {
      switch (text) {
        case 'finite':
          return '限定动词';
        case 'infinitive':
          return '不定式';
      }
    }

    return text;
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
