# Görsel Tasarım Promptu — Sezonluk

Aşağıdaki metni bir görsel tasarım aracına (Claude Design, Figma AI, v0, Galileo, Uizard vb.) olduğu gibi yapıştırın.
Kaynak: ISKELET.md §2.1 ve §3.7.

---

```
Design a high-fidelity mobile app UI (iPhone 15, 393×852 pt, portrait, dark mode only) for "Sezonluk",
a TV-series-only tracking app with personal recommendations. UI language: Turkish. Style: bold, poster-driven, content-first, similar in
layout spirit to classic social TV trackers — but fully original: no existing brand names, logos, mascots or icons.

VISUAL SYSTEM
- Background #000000, surfaces #141414 / #1F1F1F, borders #2A2A2A
- Accent yellow #FFCC00 (progress bars, primary buttons, notification bell, active tab); text on yellow #000000
- Text #FFFFFF primary, #A0A0A0 secondary; error #FF453A
- System font (SF Pro). Titles 22–28 pt bold, body 15 pt, captions 12 pt
- Posters 2:3 ratio, 6 pt corner radius; progress bar 3 pt tall directly under each poster
- Touch targets ≥ 44 pt; contrast ≥ 4.5:1
- Bottom tab bar with 3 tabs only: "Diziler" (TV icon), "Keşfet" (compass), "Profil" (person). No movies tab.
- Use realistic placeholder series posters (generic, invented artwork — not real show posters).

SCREENS TO DESIGN
1. Diziler › İzleme Listesi
   - Top segmented control: "İzleme Listesi" | "Yaklaşan" (yellow underline on active)
   - Section "Sıradaki" with a grid/list toggle icon on the right
   - 3-column poster grid; each poster has a small round check button (bottom-right),
     label "S02B05" below, and a yellow progress bar (e.g. 60% filled)
   - Section "Bir süredir izlemediklerin" — horizontal row of dimmed posters
2. Diziler › Yaklaşan
   - List grouped by date headers ("Bugün", "Yarın", "17 Ekim Cuma"); each row: small poster,
     series name, "S03B02", episode title, air date
3. Keşfet
   - Search field on top, segmented "Diziler | Kullanıcılar"
   - At the very top: a wide yellow-accented card "Sana Özel Öneriler" with a sparkle icon and chevron
   - Empty-query state: "Bu haftanın trendleri" 3-column poster grid
4. Dizi Detayı
   - Full-bleed backdrop with dark gradient, poster overlapping, title, year, status chip ("Devam ediyor")
   - Yellow "Ekle" button; overview text; season list; expanded season shows episode rows with checkboxes
5. Bölüm Sonrası (after marking an episode watched)
   - Header: episode still image, "S01B08 · Bölüm adı", series name
   - "Bu bölüm nasıldı?" — 6 emoji reactions in a row (😂 😍 😮 😢 😡 😴) with labels;
     after selection show percentage bars
   - "Bölümün yıldızı" — horizontal carousel of round actor photos with actor + character names;
     selected one has a yellow ring; results show top 5 with percentages
   - "Yorumlar" — comment input with "Spoiler içeriyor" toggle; comment cards with avatar, username,
     time, like count; one spoiler comment shown blurred with "Spoiler — göstermek için dokun"
   - Variant: user has NOT watched → all comments blurred behind a warning card
     "Bu bölümü izlemedin, yorumlar spoiler içerebilir" + "Yine de göster" button
6. Profil
   - Wide cover image (series backdrop) at top with parallax feel; yellow bell icon top-right with red badge "3"
   - Centered round avatar overlapping the cover; below: country flag emoji, "@kullaniciadi",
     share icon, outlined "Düzenle" button
   - Followers / Following / Badges counts in a row ("128 Takipçi · 96 Takip · 4 Rozet")
   - Two stat cards side by side: "Dizi izleme süresi" showing "3 ay 12 gün 7 saat" in large yellow digits,
     and "İzlenen bölüm" showing "2.418"
   - "Dizilerim" header with "Tümü ›" link, horizontal poster row
7. Bildirimler — list: new follower, comment liked, badge earned (no comment text previews)
8. Öneriler (Sana Özel Öneriler)
   - Title "Sana Özel Öneriler", subtitle "En fazla 3 kategori seç"
   - Horizontally scrolling genre chips (Dram, Komedi, Suç, Bilim Kurgu & Fantastik, Gizem, Animasyon,
     Aksiyon & Macera, Belgesel…); selected chips filled yellow with black text, others outlined
   - 3-column poster grid of recommendations; each poster has a small round "+" button (top-right)
   - Section "Gölgeler izlediğin için" — horizontal poster row of similar shows
   - Empty state variant: "Öneri almak için en az bir kategori seç"
9. Giriş / Kayıt — minimal, logo wordmark "Sezonluk" (original, simple), email + password fields,
   username field on sign-up, terms checkbox, yellow primary button

DELIVERABLES
- All 9 screens side by side on one canvas, plus a small component sheet: poster card with progress,
  primary/secondary buttons, segmented control, genre chip (selected/unselected), emoji reaction chip, comment card (normal + spoiler),
  stat card, tab bar.
```
