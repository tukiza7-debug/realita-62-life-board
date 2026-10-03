/// Glossary screen — lists cultural terms (UKT, KPR, Pinjol, TAPERA,
/// MBG, Mahar Partai, PHK, OTT KPK, BPJS, PBB, etc.) with verified
/// Indonesian and English explanations. Sources are in docs/GLOSSARY.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../brand/glossary_data.dart';

class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.glossaryTitle)),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: glossaryTerms.length,
          itemBuilder: (context, i) {
            final t = glossaryTerms[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isId ? t.shortId : t.shortEn,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isId ? t.longId : t.longEn,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
