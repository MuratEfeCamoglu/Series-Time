import 'package:flutter/services.dart';

import '../../../core/failures.dart';
import '../../../theme/app_palettes.dart';

/// F22: alternatif uygulama simgeleri. Simgeler renk paletleriyle aynı adları taşır;
/// Android'de activity-alias, iOS'ta alternatif simge setleri (MainActivity.kt, AppDelegate.swift).
class AppIconRepository {
  const AppIconRepository([this._channel = const MethodChannel(_channelName)]);

  static const _channelName = 'sezonluk/app_icon';

  final MethodChannel _channel;

  Future<AppPalette> currentIcon() => _guard(() async {
    final name = await _channel.invokeMethod<String>('current');
    return AppPalette.values.asNameMap()[name] ?? AppPalette.yellow;
  });

  Future<void> setIcon(AppPalette icon) =>
      _guard(() => _channel.invokeMethod<void>('set', {'name': icon.name}));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      throw AppFailure(AppFailureType.unknown, cause: error);
    } on MissingPluginException catch (error) {
      throw AppFailure(AppFailureType.unknown, cause: error);
    }
  }
}
