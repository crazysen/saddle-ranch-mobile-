/// Google OAuth client IDs for Sign-In → backend Sanctum exchange.
///
/// Create these in Google Cloud Console (OAuth consent + client IDs):
/// - **Web** client ID → [serverClientId] (required for ID tokens; must match Laravel `GOOGLE_CLIENT_ID`)
/// - **Android** client ID → package + SHA-1
/// - **iOS** client ID → optional [iosClientId] / Info.plist
///
/// Override at run time if needed:
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com`
class GoogleAuthConfig {
  /// Web OAuth client ID. Used as `serverClientId` so Google returns an ID token
  /// whose `aud` your Laravel API can verify.
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '1007041803805-echlrir128uqfdc7vfh1lnvojk3s38n5.apps.googleusercontent.com',
  );

  /// Optional iOS OAuth client ID (or leave empty and use GoogleService-Info.plist).
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured => serverClientId.trim().isNotEmpty;
}
