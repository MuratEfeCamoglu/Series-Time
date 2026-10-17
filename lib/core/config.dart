// Değerler derleme anında `--dart-define-from-file=env/<ortam>.json` ile gelir ve
// uygulama ikilisine gömülür; bu yüzden buraya asla gizli anahtar konmaz.

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const legalPrivacyUrl = String.fromEnvironment('LEGAL_PRIVACY_URL');
const legalTermsUrl = String.fromEnvironment('LEGAL_TERMS_URL');
