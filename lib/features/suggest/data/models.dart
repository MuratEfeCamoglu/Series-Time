/// `genres` tablosu satırı: TMDB dizi türü, Türkçe adıyla (F18b).
class Genre {
  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(id: json['id'] as int, name: json['name'] as String);

  final int id;
  final String name;
}
