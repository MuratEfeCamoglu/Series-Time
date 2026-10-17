import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Keşfet sekmesi. İçeriği (arama, trendler) Aşama 2'de gelir.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).tabDiscover)),
    );
  }
}
