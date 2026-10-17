// Değerler derleme anında `--dart-define-from-file=env/<ortam>.json` ile gelir ve
// uygulama ikilisine gömülür; bu yüzden buraya asla gizli anahtar konmaz.

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const legalPrivacyUrl = String.fromEnvironment('LEGAL_PRIVACY_URL');
const legalTermsUrl = String.fromEnvironment('LEGAL_TERMS_URL');

// Hakkında ekranındaki sürüm (F17). Release build'de Codemagic `--dart-define=APP_VERSION`
// ile pubspec sürümünü verir; paket bilgisi okuyan ek bağımlılık gerekmez.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
