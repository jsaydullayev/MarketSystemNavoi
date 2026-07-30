/// Tovar/mijoz qidiruvi uchun matn moslashtiruvchi.
///
/// Nega kerak: sotuvchi tovar do'konga QANDAY yozib kiritilganini eslab
/// qolmaydi, shuning uchun oddiy `name.contains(query)` amalda ishlamaydi.
/// Ikki asosiy nosozlik bor edi:
///
///   1. **ё / е** — tovar "включатель" deb kiril harflarida kiritilgan, ba'zilari
///      esa "ё" bilan ("щётка"). Foydalanuvchi vaqtni tejash uchun "е" bosadi
///      ("щетка") va tovar chiqmaydi. Endi ikkisi ham bir xil deb qaraladi.
///
///   2. **Ko'p so'zli nom** — "включатель 3 та VIKO" tovarini topish uchun
///      foydalanuvchi "включатель VIKO" deb yozadi. Bu yaxlit BO'LAK sifatida
///      nomda uchramaydi (orasida "3 та" bor), shuning uchun oddiy `contains`
///      hech narsa qaytarmasdi. Endi so'rov so'zlarga bo'linadi va HAR BIR so'z
///      nomda bo'lsa yetarli — tartibi ham muhim emas ("VIKO включатель" ham
///      topadi).
///
/// Qo'shimcha: apostrof shakllari birxillashtiriladi. O'zbek nomlarida
/// `o'rindiq` / `oʻrindiq` / `o‘rindiq` / `orindiq` — hammasi bir xil tovar,
/// lekin turli klaviaturada turlicha yoziladi.
///
/// ATAYLAB qilinmagan narsalar: `й`↔`и` va `ў`↔`у` birlashtirilmaydi — bular
/// alohida harflar, ularni tenglashtirish noto'g'ri natijalarni ko'paytiradi.
/// Kiril↔lotin transliteratsiyasi ham yo'q (bu alohida, kattaroq masala).
class SearchMatcher {
  const SearchMatcher._();

  // Apostrofga o'xshash barcha belgilar: ASCII ', modifier letter turned/apostrophe,
  // tipografik ' va ', teskari apostrof va akut.
  static final RegExp _apostrophes = RegExp(
    "['ʻʼ‘’`´′]",
  );

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Solishtirish uchun matnni bir ko'rinishga keltiradi:
  /// kichik harf → `ё`/`е` birlashtirish → apostroflarni olib tashlash →
  /// ketma-ket bo'shliqlarni bittaga siqish.
  static String normalize(String input) {
    if (input.isEmpty) return '';
    return input
        .toLowerCase()
        // toLowerCase 'Ё' ni 'ё' ga o'giradi, shuning uchun bitta almashtirish
        // ikkala registrni ham qamrab oladi.
        .replaceAll('ё', 'е')
        .replaceAll(_apostrophes, '')
        .replaceAll(_whitespace, ' ')
        .trim();
  }

  /// So'rovni qidiriladigan so'zlarga bo'ladi. Bo'sh so'rov — bo'sh ro'yxat.
  static List<String> tokenize(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return const [];
    return normalized.split(' ').where((t) => t.isNotEmpty).toList();
  }

  /// [haystack] ichida [query]ning BARCHA so'zlari bormi.
  ///
  /// Bo'sh so'rov hamma narsaga mos keladi (filtr o'chirilgan holat).
  static bool matches(String? haystack, String query) {
    final tokens = tokenize(query);
    if (tokens.isEmpty) return true;

    final target = normalize(haystack ?? '');
    if (target.isEmpty) return false;

    for (final token in tokens) {
      if (!target.contains(token)) return false;
    }
    return true;
  }

  /// Bir nechta maydon bo'yicha qidirish (masalan nom + shtrix-kod + izoh):
  /// har bir so'z maydonlarning ISTALGAN birida uchrasa yetarli. Shu tufayli
  /// "VIKO 998901" kabi aralash so'rov ham ishlaydi.
  static bool matchesAny(Iterable<String?> haystacks, String query) {
    final tokens = tokenize(query);
    if (tokens.isEmpty) return true;

    final targets = haystacks
        .map((h) => normalize(h ?? ''))
        .where((h) => h.isNotEmpty)
        .toList();
    if (targets.isEmpty) return false;

    for (final token in tokens) {
      if (!targets.any((t) => t.contains(token))) return false;
    }
    return true;
  }
}
