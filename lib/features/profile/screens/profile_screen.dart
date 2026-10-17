import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Profil sekmesi. İçeriği Aşama 1 ve 4'te gelir.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).tabProfile)),
    );
  }
}
