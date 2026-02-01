import 'package:intl/intl.dart';

class Format {
  static final _money = NumberFormat.decimalPattern();
  static const _iqPrefixes = <String>['077', '078', '079', '074', '075'];

  static String money(num? v) {
    if (v == null) return '—';
    return _money.format(v);
  }

  static String digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Returns an Arabic error message if invalid, otherwise null.
  static String? validateIraqiPhone(String input) {
    final digits = digitsOnly(input);
    if (digits.isEmpty) return 'يرجى إدخال رقم الهاتف';
    if (digits.length != 11) return 'رقم الهاتف يجب أن يكون 11 رقم';
    if (!_iqPrefixes.any(digits.startsWith)) {
      return 'رقم الهاتف يجب أن يبدأ بـ 077 أو 078 أو 079 أو 074 أو 075';
    }
    return null;
  }

  static String ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String dmy(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final m = d.month.toString().padLeft(2, '0');
    final y = d.year.toString().padLeft(4, '0');
    return '$day-$m-$y';
  }

  static String govName(String? name) {
    if (name == null) return '—';
    final raw = name.trim();
    if (raw.isEmpty) return '—';
    final key = raw.toLowerCase();
    const map = <String, String>{
      'baghdad': 'بغداد',
      'basra': 'البصرة',
      'erbil': 'أربيل',
      'dohuk': 'دهوك',
      'duhok': 'دهوك',
      'sulaymaniyah': 'السليمانية',
      'sulaimaniyah': 'السليمانية',
      'najaf': 'النجف',
      'karbala': 'كربلاء',
      'kirkuk': 'كركوك',
      'diyala': 'ديالى',
      'anbar': 'الأنبار',
      'nineveh': 'نينوى',
      'mosul': 'نينوى',
      'babil': 'بابل',
      'babylon': 'بابل',
      'wasit': 'واسط',
      'maysan': 'ميسان',
      'thi qar': 'ذي قار',
      'dhi qar': 'ذي قار',
      'saladin': 'صلاح الدين',
      'salah ad din': 'صلاح الدين',
      'qadisiyah': 'القادسية',
      'diwaniyah': 'القادسية',
      'mutanna': 'المثنى',
    };
    return map[key] ?? raw;
  }
}
