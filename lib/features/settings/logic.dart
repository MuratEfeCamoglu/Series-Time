/// F16 saf kuralları: hesap silme onayı.
library;

/// Kullanıcı adı büyük/küçük harf ve baştaki/sondaki boşluk gözetmeden eşleşmelidir;
/// kullanıcı adları zaten küçük harfle saklanır (F1a).
bool deleteConfirmationMatches(String typed, String username) =>
    typed.trim().toLowerCase() == username;
