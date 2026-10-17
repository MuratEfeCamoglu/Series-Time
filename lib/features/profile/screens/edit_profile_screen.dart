import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/logic.dart';
import '../../shows/providers.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/avatar_crop_view.dart';
import '../widgets/avatar_image_picker_sheet.dart';
import '../widgets/country_picker_sheet.dart';
import '../widgets/cover_picker_sheet.dart';
import '../widgets/profile_avatar.dart';

/// F2: görünen ad, kullanıcı adı, ülke, biyografi, avatar, kapak ve sosyal bağlantılar.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider);
    return profile.when(
      data: (profile) => _EditProfileForm(profile: profile),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.editProfileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.editProfileTitle)),
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _displayName = TextEditingController(
    text: widget.profile.displayName,
  );
  late final _username = TextEditingController(text: widget.profile.username);
  late final _bio = TextEditingController(text: widget.profile.bio);
  late final _letterboxd = TextEditingController(
    text: widget.profile.letterboxdUsername,
  );
  late final _instagram = TextEditingController(
    text: widget.profile.instagramUsername,
  );
  late String? _countryCode = widget.profile.countryCode;
  late int? _coverShowId = widget.profile.coverShowId;
  late String? _coverPath = widget.profile.coverPath;
  String? _coverLabel;
  Uint8List? _avatarBytes;
  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    _letterboxd.dispose();
    _instagram.dispose();
    super.dispose();
  }

  /// F2: avatar galeriden veya bir dizinin arka plan/afiş görsellerinden; ikisi de kare kırpılır.
  Future<void> _chooseAvatarSource() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_AvatarSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('avatar.gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.avatarFromGallery),
              onTap: () => Navigator.pop(sheetContext, _AvatarSource.gallery),
            ),
            ListTile(
              key: const Key('avatar.show'),
              leading: const Icon(Icons.movie_outlined),
              title: Text(l10n.avatarFromShow),
              onTap: () => Navigator.pop(sheetContext, _AvatarSource.show),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    switch (source) {
      case _AvatarSource.gallery:
        await _pickAvatar();
      case _AvatarSource.show:
        final path = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AvatarImagePickerSheet(),
        );
        final url = tmdbImageUrl(path, TmdbImageSize.w780);
        if (url != null && mounted) {
          await _crop(CachedNetworkImageProvider(url));
        }
    }
  }

  Future<void> _crop(ImageProvider image) async {
    final bytes = await showAvatarCrop(context, image);
    if (bytes == null || !mounted) return;
    if (!isValidAvatarSize(bytes.length)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorFileTooLarge)),
      );
      return;
    }
    setState(() => _avatarBytes = bytes);
  }

  Future<void> _pickAvatar() async {
    // Kırpmada yakınlaştırma payı kalsın diye 512'den büyük okunur; çıktı yine 512×512.
    final file = await ref
        .read(imagePickerProvider)
        .pickImage(
          source: ImageSource.gallery,
          maxWidth: avatarOutputSize * 2,
          maxHeight: avatarOutputSize * 2,
          imageQuality: 85,
          requestFullMetadata: false,
        );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _crop(MemoryImage(bytes));
  }

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<CountrySelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CountryPickerSheet(selected: _countryCode),
    );
    if (result != null) setState(() => _countryCode = result.code);
  }

  Future<void> _pickCover() async {
    final result = await showModalBottomSheet<CoverSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CoverPickerSheet(selectedPath: _coverPath),
    );
    if (result == null) return;
    setState(() {
      _coverShowId = result.show?.id;
      _coverPath = result.path;
      _coverLabel = result.show?.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(myProfileProvider.notifier)
          .save(
            ProfileEdit(
              username: normalizeUsername(_username.text),
              displayName: _displayName.text,
              bio: _bio.text,
              countryCode: _countryCode,
              coverShowId: _coverShowId,
              coverPath: _coverPath,
              letterboxdUsername: normalizeSocialUsername(_letterboxd.text),
              instagramUsername: normalizeSocialUsername(_instagram.text),
              avatarBytes: _avatarBytes,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
      );
      context.pop();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _coverName(WidgetRef ref) {
    final label = _coverLabel;
    if (label != null) return label;
    for (final entry in ref.watch(myShowsProvider).value ?? const []) {
      if (entry.show.id == _coverShowId) return entry.show.name;
    }
    // Listede olmayan bir diziden seçilmiş kapak.
    return _coverPath == null ? null : AppLocalizations.of(context).coverChosen;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatarPath = widget.profile.avatarPath;
    final country = _countryCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        actions: [
          TextButton(
            key: const Key('editProfile.save'),
            onPressed: _saving ? null : _save,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (_saving) const LinearProgressIndicator(),
            Center(
              child: ProfileAvatar(
                bytes: _avatarBytes,
                url: avatarPath == null
                    ? null
                    : ref.read(profileRepositoryProvider).avatarUrl(avatarPath),
              ),
            ),
            Center(
              child: TextButton(
                key: const Key('editProfile.avatar'),
                onPressed: _saving ? null : _chooseAvatarSource,
                child: Text(l10n.changeAvatar),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('editProfile.displayName'),
              controller: _displayName,
              decoration: InputDecoration(labelText: l10n.fieldDisplayName),
              maxLength: maxDisplayNameLength,
              validator: (value) => isValidDisplayName(value ?? '')
                  ? null
                  : l10n.validationDisplayNameLength,
            ),
            TextFormField(
              key: const Key('editProfile.username'),
              controller: _username,
              decoration: InputDecoration(
                labelText: l10n.fieldUsername,
                prefixText: '@',
              ),
              autocorrect: false,
              validator: (value) =>
                  isValidUsername(normalizeUsername(value ?? ''))
                  ? null
                  : l10n.validationUsernameFormat,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('editProfile.bio'),
              controller: _bio,
              decoration: InputDecoration(labelText: l10n.fieldBio),
              maxLength: maxBioLength,
              maxLines: 4,
              minLines: 2,
              validator: (value) =>
                  isValidBio(value ?? '') ? null : l10n.validationBioLength,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldCountry),
              trailing: Text(
                country == null
                    ? l10n.countryNone
                    : '${countryFlag(country)}  $country',
                style: AppTextStyles.body,
              ),
              onTap: _saving ? null : _pickCountry,
            ),
            ListTile(
              key: const Key('editProfile.cover'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldCover),
              trailing: Text(
                _coverName(ref) ?? l10n.coverNone,
                style: AppTextStyles.body,
              ),
              onTap: _saving ? null : _pickCover,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('editProfile.letterboxd'),
              controller: _letterboxd,
              decoration: InputDecoration(
                labelText: l10n.fieldLetterboxd,
                prefixText: '@',
              ),
              autocorrect: false,
              validator: (value) {
                final username = normalizeSocialUsername(value ?? '');
                return username == null || isValidLetterboxdUsername(username)
                    ? null
                    : l10n.validationLetterboxd;
              },
            ),
            TextFormField(
              key: const Key('editProfile.instagram'),
              controller: _instagram,
              decoration: InputDecoration(
                labelText: l10n.fieldInstagram,
                prefixText: '@',
                errorMaxLines: 2,
              ),
              autocorrect: false,
              validator: (value) {
                final username = normalizeSocialUsername(value ?? '');
                return username == null || isValidInstagramUsername(username)
                    ? null
                    : l10n.validationInstagram;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(failureMessage(l10n, _error!), style: AppTextStyles.error),
            ],
          ],
        ),
      ),
    );
  }
}

enum _AvatarSource { gallery, show }
