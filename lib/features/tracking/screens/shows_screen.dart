import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Diziler sekmesi. İçeriği (İzleme Listesi, Yaklaşan) Aşama 3'te gelir.
class ShowsScreen extends StatelessWidget {
  const ShowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).tabShows)),
    );
  }
}
