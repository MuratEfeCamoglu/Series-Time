-- F9(a): tepki sayısı 6'dan 12'ye çıkarıldı (kullanıcı kararı). Mevcut değerler ve satırlar değişmez.
alter type public.reaction_emoji add value if not exists 'mindblown';
alter type public.reaction_emoji add value if not exists 'scared';
alter type public.reaction_emoji add value if not exists 'epic';
alter type public.reaction_emoji add value if not exists 'thoughtful';
alter type public.reaction_emoji add value if not exists 'touched';
alter type public.reaction_emoji add value if not exists 'tense';
