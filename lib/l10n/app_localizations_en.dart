// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sezonluk';

  @override
  String get tabShows => 'Shows';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabProfile => 'Profile';

  @override
  String get retry => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get errorNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get errorInvalidCredentials => 'Wrong email or password.';

  @override
  String get errorEmailNotConfirmed =>
      'Verify your email. You can sign in after tapping the link in your inbox.';

  @override
  String get errorUsernameTaken => 'This username is taken.';

  @override
  String get errorWeakPassword => 'Password must be at least 8 characters.';

  @override
  String get errorSamePassword =>
      'The new password can\'t be the same as the old one.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get errorFileTooLarge => 'The image can\'t be larger than 2 MB.';

  @override
  String get errorLinkOpen => 'Couldn\'t open the link.';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldPasswordRepeat => 'Password (again)';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldDisplayName => 'Display name';

  @override
  String get fieldBio => 'Bio';

  @override
  String get fieldCountry => 'Country';

  @override
  String get validationEmailInvalid => 'Enter a valid email address.';

  @override
  String get validationPasswordShort =>
      'Password must be at least 8 characters.';

  @override
  String get validationPasswordMismatch => 'Passwords don\'t match.';

  @override
  String get validationUsernameFormat =>
      '3–20 characters; only lowercase letters, digits and _.';

  @override
  String get validationDisplayNameLength =>
      'Display name must be 1–40 characters.';

  @override
  String get validationBioLength => 'Bio can be at most 160 characters.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInToSignUp => 'No account? Sign up';

  @override
  String get signInForgotPassword => 'Forgot password';

  @override
  String get signUpTitle => 'Sign up';

  @override
  String get signUpButton => 'Sign up';

  @override
  String get signUpToSignIn => 'Already have an account? Sign in';

  @override
  String get signUpConsent =>
      'I have read and accept the Terms of Use and the Privacy Policy.';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get signUpCheckEmailTitle => 'Verify your email';

  @override
  String signUpCheckEmailBody(String email) {
    return 'We sent a verification link to $email. You can sign in after tapping it.';
  }

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordBody =>
      'Enter your account\'s email address and we\'ll send you a link to reset your password.';

  @override
  String get forgotPasswordButton => 'Send link';

  @override
  String get forgotPasswordSent =>
      'Email sent. The link in your inbox opens the new password screen in the app.';

  @override
  String get resetPasswordTitle => 'Set a new password';

  @override
  String get resetPasswordButton => 'Save password';

  @override
  String get resetPasswordDone => 'Your password has been updated.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get changeAvatar => 'Change avatar';

  @override
  String get countryNone => 'Not specified';

  @override
  String get countryPickerTitle => 'Choose country';

  @override
  String get countrySearchHint => 'Search country code (e.g. US)';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get signOut => 'Sign out';

  @override
  String get errorTmdbUnavailable =>
      'Show information is unavailable right now. Try again in a moment.';

  @override
  String get saveFailed => 'Couldn\'t save, try again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get noResults => 'No results found';

  @override
  String get discoverSegmentShows => 'Shows';

  @override
  String get discoverSegmentUsers => 'Users';

  @override
  String get discoverSearchShowsHint => 'Search shows';

  @override
  String get discoverSearchUsersHint => 'Search usernames';

  @override
  String get discoverSearchMinChars => 'Type at least 2 characters to search.';

  @override
  String get showStatusOngoing => 'Ongoing';

  @override
  String get showStatusEnded => 'Ended';

  @override
  String get showAdd => 'Add';

  @override
  String get showRemove => 'Remove from list';

  @override
  String get showRemoveConfirmTitle => 'Remove from your list?';

  @override
  String showRemoveConfirmBody(String name) {
    return '$name will be removed from your list and its watch history will be deleted.';
  }

  @override
  String get showRemoveConfirmButton => 'Remove';

  @override
  String get showSeasons => 'Seasons';

  @override
  String get showSpecials => 'Specials';

  @override
  String seasonTitle(int number) {
    return 'Season $number';
  }

  @override
  String seasonEpisodeCount(int count) {
    return '$count episodes';
  }

  @override
  String get episodeNoAirDate => 'Air date unknown';

  @override
  String get seasonNoEpisodes => 'No episode information for this season yet.';

  @override
  String get showsEmpty => 'You haven\'t added any shows yet';

  @override
  String get showsGoToDiscover => 'Go to Discover';

  @override
  String get tabWatchlist => 'Up next';

  @override
  String get tabUpcoming => 'Upcoming';

  @override
  String get watchlistUpNext => 'Continue watching';

  @override
  String get watchlistNotRecently => 'Haven\'t watched in a while';

  @override
  String get watchlistAllCaughtUp => 'No new episodes to watch';

  @override
  String markNextEpisode(String code) {
    return 'I watched $code';
  }

  @override
  String get upcomingEmpty => 'No upcoming episodes';

  @override
  String get upcomingToday => 'Today';

  @override
  String get upcomingTomorrow => 'Tomorrow';

  @override
  String get seasonMarkAll => 'I watched the whole season';

  @override
  String get episodeMarkUntil => 'Watched up to here';

  @override
  String get episodeMarkWatched => 'Watched';

  @override
  String get episodeTitle => 'Episode';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileShare => 'Share profile';

  @override
  String profileShareText(String link) {
    return 'Check out the shows I watch on Sezonluk: $link';
  }

  @override
  String get statWatchTimeTitle => 'Time spent watching';

  @override
  String statWatchTimeValue(int months, int days, int hours) {
    return '$months mo $days d $hours h';
  }

  @override
  String get statEpisodesTitle => 'Episodes watched';

  @override
  String get statFollowers => 'Followers';

  @override
  String get statFollowing => 'Following';

  @override
  String get statBadges => 'Badges';

  @override
  String get profileMyShows => 'My shows';

  @override
  String get profileSeeAll => 'See all';

  @override
  String get profileNoShows => 'No shows added yet.';

  @override
  String get fieldCover => 'Cover';

  @override
  String get coverNone => 'Automatic';

  @override
  String get coverPickerTitle => 'Choose cover';

  @override
  String get coverPickerHint =>
      'Pick a show, then make one of its backdrops your cover. If you don\'t choose, the show you watched last is used.';

  @override
  String get suggestCardTitle => 'Picked for you';

  @override
  String get suggestTitle => 'Picked for you';

  @override
  String get suggestMaxGenres => 'You can pick up to 3 categories';

  @override
  String get suggestPickGenre =>
      'Pick at least one category to get suggestions';

  @override
  String get suggestEmpty => 'No new suggestions left in these categories';

  @override
  String get suggestByGenre => 'From your categories';

  @override
  String suggestSimilarTitle(String name) {
    return 'Because you watched $name';
  }

  @override
  String suggestAddShow(String name) {
    return 'Add $name to your list';
  }

  @override
  String get errorCommentRateLimited =>
      'You\'re commenting too fast. Wait a moment and try again.';

  @override
  String get errorCommentBannedWord =>
      'Your comment contains an inappropriate word.';

  @override
  String get reactionsTitle => 'Your mood';

  @override
  String get reactionFunny => 'Funny';

  @override
  String get reactionLove => 'Loved it';

  @override
  String get reactionShocked => 'Shocked';

  @override
  String get reactionSad => 'Sad';

  @override
  String get reactionAngry => 'Angry';

  @override
  String get reactionBored => 'Bored';

  @override
  String percent(int value) {
    return '$value%';
  }

  @override
  String get starTitle => 'Star of the episode';

  @override
  String get starNoCast => 'No cast information for this episode';

  @override
  String get starResultsTitle => 'Most voted';

  @override
  String starVoteFor(String name) {
    return 'Vote for $name';
  }

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentHint => 'Write a comment';

  @override
  String get commentSpoilerSwitch => 'Contains spoilers';

  @override
  String get commentSend => 'Send';

  @override
  String get commentTooLong => 'Comments must be 1–500 characters.';

  @override
  String get commentsEmpty => 'No comments yet. Be the first.';

  @override
  String get commentsSpoilerGate =>
      'You haven\'t watched this episode; comments may contain spoilers';

  @override
  String get commentsShowAnyway => 'Show anyway';

  @override
  String get commentSpoilerHidden => 'Contains spoilers — tap to see';

  @override
  String get commentsLoadMore => 'More comments';

  @override
  String get commentLike => 'Like';

  @override
  String get commentUnlike => 'Unlike';

  @override
  String get commentMenu => 'Comment options';

  @override
  String get commentDelete => 'Delete';

  @override
  String get commentDeleteConfirm => 'Delete your comment?';

  @override
  String get report => 'Report';

  @override
  String get reportTitle => 'Reason for report';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonSpoiler => 'Spoiler';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportNoteHint => 'Note (optional)';

  @override
  String get reportSend => 'Send';

  @override
  String get reportSent =>
      'Thanks, we received your report and will review it.';

  @override
  String get block => 'Block';

  @override
  String blockConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get blockConfirmBody =>
      'You won\'t see their comments and they won\'t be able to follow you.';

  @override
  String blockDone(String name) {
    return '$name blocked.';
  }

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get blockedUsersEmpty => 'You haven\'t blocked anyone.';

  @override
  String get unblock => 'Unblock';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get profileMenu => 'Profile options';

  @override
  String get followersTitle => 'Followers';

  @override
  String get followingTitle => 'Following';

  @override
  String get followersEmpty => 'No followers yet.';

  @override
  String get followingEmpty => 'Not following anyone yet.';

  @override
  String get userShowsTitle => 'Shows';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications in the last 90 days.';

  @override
  String notificationNewFollower(String name) {
    return '$name started following you.';
  }

  @override
  String notificationCommentLiked(String name) {
    return '$name liked your comment.';
  }

  @override
  String notificationBadgeEarned(String badge) {
    return 'You earned the \"$badge\" badge!';
  }

  @override
  String get notificationDeletedUser => 'A user';

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgeEarnedOn(String date) {
    return 'Earned on $date';
  }

  @override
  String get badgeLocked => 'Not earned yet';

  @override
  String get errorUsernameMismatch => 'Username doesn\'t match.';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountBody =>
      'Your account, profile, watch history, comments, reactions, follows and avatar will be permanently deleted. This can\'t be undone.';

  @override
  String deleteAccountPrompt(String username) {
    return 'Type your username to confirm: $username';
  }

  @override
  String get deleteAccountButton => 'Permanently delete my account';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutTmdbAttribution =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get aboutTmdbLogo => 'TMDB logo';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get guestContinue => 'Continue as guest';

  @override
  String get guestGateTitle => 'Create an account for this';

  @override
  String get guestGateBody =>
      'Open a free account to track your shows, mark episodes, comment and follow your friends.';

  @override
  String get guestHaveAccount => 'I have an account, sign in';

  @override
  String get reactionMindblown => 'Mind blown';

  @override
  String get reactionScared => 'Scared';

  @override
  String get reactionEpic => 'Epic';

  @override
  String get reactionThoughtful => 'Thought-provoking';

  @override
  String get reactionTouched => 'Touched';

  @override
  String get reactionTense => 'Tense';

  @override
  String get onTheAirTitle => 'On the air';

  @override
  String episodeStill(String code) {
    return 'Still from $code';
  }

  @override
  String get episodeWatched => 'Watched';

  @override
  String get episodeMarkAsWatched => 'Mark as watched';

  @override
  String episodeRuntime(int minutes) {
    return '$minutes min';
  }

  @override
  String get watchlistNotStarted => 'Not started yet';

  @override
  String get seasonPremiere => 'Season premiere';

  @override
  String remainingEpisodes(int count) {
    return '+$count';
  }

  @override
  String get showTabAbout => 'About';

  @override
  String get showTabEpisodes => 'Episodes';

  @override
  String get showNextEpisode => 'Up next';

  @override
  String get showAllWatched => 'You\'ve watched it all!';

  @override
  String get showAllEpisodes => 'All episodes';

  @override
  String seasonProgress(int watched, int total) {
    return '$watched/$total';
  }

  @override
  String get seasonCompleted => 'Season completed';

  @override
  String get discoverPopularTitle => 'Most popular shows';

  @override
  String get showCastTitle => 'Cast';

  @override
  String get showCastEmpty => 'No cast information.';

  @override
  String get seasonExpand => 'Show episodes';

  @override
  String get seasonCollapse => 'Hide episodes';

  @override
  String get ratingTitle => 'Your rating';

  @override
  String get ratingNone => 'No ratings yet.';

  @override
  String ratingAverage(String average, int count) {
    return 'Average $average · $count ratings';
  }

  @override
  String ratingStar(int count) {
    return '$count stars';
  }

  @override
  String get episodeLike => 'Like episode';

  @override
  String get episodeUnlike => 'Unlike';

  @override
  String get coverNoImages => 'This show has no backdrops.';

  @override
  String get coverChosen => 'Selected image';

  @override
  String get pickerMyShows => 'Shows in your list';

  @override
  String get pickerSearchResults => 'Search results';

  @override
  String get pickerSearchHint => 'Search for a show.';

  @override
  String get avatarFromGallery => 'Choose from gallery';

  @override
  String get statusFinished => 'Finished';

  @override
  String get statusUpToDate => 'Up to date';

  @override
  String get statusWatching => 'Watching';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusDropped => 'Dropped';

  @override
  String get statusWatchlist => 'Watchlist';

  @override
  String statusAuto(String status) {
    return 'Automatic ($status)';
  }

  @override
  String get statusMenuTitle => 'Show status';

  @override
  String get statusFilterAll => 'All';

  @override
  String get statusFilterEmpty => 'No shows in this group.';

  @override
  String statusProgressLabel(String status, int watched, int aired) {
    return '$status, $watched/$aired episodes watched';
  }

  @override
  String get avatarFromShow => 'Choose from show images';

  @override
  String get avatarPickerTitle => 'Choose image';

  @override
  String get avatarNoImages => 'This show has no images.';

  @override
  String get cropTitle => 'Crop';

  @override
  String get cropHint => 'Drag and zoom to adjust the square.';

  @override
  String get cropDone => 'Use';

  @override
  String get fieldLetterboxd => 'Letterboxd profile link';

  @override
  String get fieldInstagram => 'Instagram profile link';

  @override
  String get validationLetterboxd =>
      'Enter a valid Letterboxd profile link (letterboxd.com/username; short boxd.it links don\'t work).';

  @override
  String get validationInstagram =>
      'Enter a valid Instagram profile link (instagram.com/username).';

  @override
  String get recentShowsTitle => 'Recently watched';

  @override
  String get upcomingShowAll => 'Show all';

  @override
  String get upcomingShowLess => 'Show less';

  @override
  String get profileFavorites => 'Favorite shows';

  @override
  String get profileFavoritesHint =>
      'Use the heart button on a show\'s page to pick up to 4 favorites.';

  @override
  String get profileWatching => 'Currently watching';

  @override
  String get profileWatchingEmpty => 'You\'re not watching anything right now.';

  @override
  String get profileRecentActivity => 'Recent activity';

  @override
  String profileSince(String date) {
    return 'Since $date';
  }

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String get favoritesLimit => 'You can pick up to 4 favorites.';

  @override
  String get layoutMenu => 'View';

  @override
  String get layoutList => 'List';

  @override
  String get layoutGrid => 'Grid';

  @override
  String get layoutPoster => 'Posters';

  @override
  String get friendsActivityTitle => 'Your friends are watching';

  @override
  String friendRating(String rating) {
    return '$rating stars';
  }

  @override
  String profileSaveFailedHint(String reason) {
    return 'Couldn\'t save profile: $reason';
  }

  @override
  String get validationFixFields => 'Fix the fields marked in red.';

  @override
  String get hintLetterboxd => 'https://letterboxd.com/username/';

  @override
  String get hintInstagram => 'https://www.instagram.com/username/';

  @override
  String get profileRatings => 'Ratings';

  @override
  String profileRatingsSummary(int count, String average) {
    return '$count ratings · average $average';
  }

  @override
  String get profileRatingsEmpty =>
      'Ratings you give on episode pages show up here as a chart.';

  @override
  String ratingBarLabel(String rating, int count) {
    return '$rating stars: $count episodes';
  }

  @override
  String get posterPickerTitle => 'Poster';

  @override
  String get posterPickerEmpty => 'This show has no other posters.';

  @override
  String get posterDefault => 'Default';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get notificationsMe => 'Me';

  @override
  String get notificationsFriends => 'Friends';

  @override
  String get friendsFeedEmpty =>
      'Episodes, ratings and badges of the people you follow show up here.';

  @override
  String feedWatchedOne(String user, String show, String code) {
    return '@$user watched: $show · $code';
  }

  @override
  String feedWatchedMany(String user, int count, String show) {
    return '@$user watched $count episodes: $show';
  }

  @override
  String feedRated(String user, String show, String code, String rating) {
    return '@$user rated: $show · $code · $rating ★';
  }

  @override
  String feedBadge(String user, String badge) {
    return '@$user earned the \"$badge\" badge';
  }

  @override
  String unreadNotifications(int count) {
    return '$count unread notifications';
  }

  @override
  String get settingsColors => 'Color';

  @override
  String get settingsColorsHint =>
      'Choose the app\'s accent color and background tones. Changes apply right away.';

  @override
  String get paletteYellow => 'Yellow';

  @override
  String get palettePurple => 'Purple';

  @override
  String get paletteBlue => 'Blue';

  @override
  String get paletteGreen => 'Green';

  @override
  String get paletteRed => 'Red';

  @override
  String get paletteOrange => 'Orange';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageHint =>
      'The interface language changes right away. Show and episode titles and summaries are shown in Turkish for now.';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get badgeFirstEpisodeName => 'First Episode';

  @override
  String get badgeFirstEpisodeDesc => 'Mark your first episode as watched.';

  @override
  String get badgeEpisodes10Name => 'Warm-up';

  @override
  String get badgeEpisodes10Desc => 'Watch 10 episodes.';

  @override
  String get badgeEpisodes50Name => 'Habit';

  @override
  String get badgeEpisodes50Desc => 'Watch 50 episodes.';

  @override
  String get badgeEpisodes100Name => 'Series Addict';

  @override
  String get badgeEpisodes100Desc => 'Watch 100 episodes.';

  @override
  String get badgeEpisodes500Name => 'Screen Junkie';

  @override
  String get badgeEpisodes500Desc => 'Watch 500 episodes.';

  @override
  String get badgeEpisodes1000Name => 'Marathon Master';

  @override
  String get badgeEpisodes1000Desc => 'Watch 1,000 episodes.';

  @override
  String get badgeEpisodes5000Name => 'Legendary Viewer';

  @override
  String get badgeEpisodes5000Desc => 'Watch 5,000 episodes.';

  @override
  String get badgeShows10Name => 'Collector';

  @override
  String get badgeShows10Desc => 'Add 10 shows to your list.';

  @override
  String get badgeShows25Name => 'Archivist';

  @override
  String get badgeShows25Desc => 'Add 25 shows to your list.';

  @override
  String get badgeShows50Name => 'Librarian';

  @override
  String get badgeShows50Desc => 'Add 50 shows to your list.';

  @override
  String get badgeFirstFinishedName => 'Final Scene';

  @override
  String get badgeFirstFinishedDesc =>
      'Watch every episode of a finished show.';

  @override
  String get badgeFinished5Name => 'Finisher';

  @override
  String get badgeFinished5Desc => 'Watch every episode of 5 finished shows.';

  @override
  String get badgeFirstCommentName => 'First Word';

  @override
  String get badgeFirstCommentDesc => 'Write your first comment.';

  @override
  String get badgeComments10Name => 'Chatterbox';

  @override
  String get badgeComments10Desc => 'Write 10 comments.';

  @override
  String get badgeComments50Name => 'Critic';

  @override
  String get badgeComments50Desc => 'Write 50 comments.';

  @override
  String meWatchedOne(String show, String code) {
    return 'You watched: $show · $code';
  }

  @override
  String meWatchedMany(int count, String show) {
    return 'You watched $count episodes: $show';
  }

  @override
  String get discoverSearchTooltip => 'Search';

  @override
  String socialLetterboxdLabel(String name) {
    return 'Letterboxd: $name';
  }

  @override
  String socialInstagramLabel(String name) {
    return 'Instagram: $name';
  }

  @override
  String get categoryAnime => 'Anime';

  @override
  String get categoryKorean => 'Korean shows';

  @override
  String get categoryTurkish => 'Turkish shows';

  @override
  String get categoryJapanese => 'Japanese shows';

  @override
  String get categoryBritish => 'British shows';

  @override
  String get categorySpanish => 'Spanish shows';

  @override
  String get categoryMiniseries => 'Miniseries';

  @override
  String get categoryRecent => 'New releases';

  @override
  String get categoryTopRated => 'Top rated';

  @override
  String get settingsAppIcon => 'App icon';

  @override
  String get settingsAppIconHint =>
      'Choose the color of the home screen icon. On some phones the icon changes after a few seconds.';

  @override
  String get appIconFailed => 'Couldn\'t change the icon, try again.';

  @override
  String get unitMonths => 'mo';

  @override
  String get unitDays => 'd';

  @override
  String get unitHours => 'h';

  @override
  String get unitEpisodes => 'episodes';
}
