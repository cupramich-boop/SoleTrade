/// Gotowe opcje do wyboru przy wystawianiu oferty.
class ProductOptions {
  ProductOptions._();

  static const List<String> sizes = [
    '35-38',
    '39-42',
    '43-46',
    '47-50',
    'Uniwersalny',
  ];

  static const List<String> materials = [
    'Bawełna',
    'Poliester',
    'Wełna',
    'Nylon',
    'Elastan',
    'Bambus',
    'Mieszanka',
    'Inny',
  ];

  static const List<int> conditionDaysOptions = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    14,
    30,
    60,
    90,
  ];

  static String conditionDaysLabel(int days) {
    if (days == 0) return 'Nowe (nieużywane)';
    if (days == 1) return '1 dzień';
    if (days < 7) return '$days dni';
    if (days < 14) return '1 tydzień';
    if (days < 30) return '${(days / 7).round()} tygodnie';
    if (days < 60) return '1 miesiąc';
    return '${(days / 30).round()} miesiące';
  }
}
