import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../storage/app_storage.dart';

/// Quản lý ngôn ngữ toàn app (Tiếng Việt / English) với lưu trữ bền vững.
class LocaleService extends ChangeNotifier {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const String _localeKey = 'cone_app_locale';
  String _localeCode = 'vi';

  String get localeCode => _localeCode;
  bool get isEnglish => _localeCode == 'en';
  bool get isVietnamese => _localeCode != 'en';
  Locale get locale => Locale(_localeCode);

  /// Trả về chuỗi theo ngôn ngữ hiện tại.
  String text(String vi, String en) => isEnglish ? en : vi;

  Future<void> loadLocale() async {
    try {
      final saved = await AppStorage.instance.getString(_localeKey);
      if (saved == 'en' || saved == 'vi') {
        _localeCode = saved!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLocale(String code) async {
    final normalized = code == 'en' ? 'en' : 'vi';
    if (_localeCode == normalized) return;
    _localeCode = normalized;
    notifyListeners();
    try {
      await AppStorage.instance.setString(_localeKey, normalized);
    } catch (_) {}
  }

  Future<void> toggleLocale() async {
    await setLocale(isEnglish ? 'vi' : 'en');
  }
}

/// Hàm viết tắt giúp dịch nhanh bất kỳ chuỗi giao diện nào: `tr('Trang chủ', 'Home')`
String tr(String vi, String en) => LocaleService.instance.text(vi, en);

/// Nút chuyển nhanh VI | EN nhỏ gọn cho màn hình Đăng nhập / AppBar
class LanguageToggleChip extends StatelessWidget {
  const LanguageToggleChip({
    super.key,
    this.lightOnDark = false,
  });

  final bool lightOnDark;

  @override
  Widget build(BuildContext context) {
    final isEn = LocaleService.instance.isEnglish;
    final bg = lightOnDark
        ? Colors.black.withValues(alpha: 0.28)
        : AppColors.adaptiveCard;
    final border = lightOnDark
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.adaptiveBorder;
    final activeColor = lightOnDark ? Colors.white : AppColors.primary;
    final inactiveColor = lightOnDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppColors.adaptiveTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => LocaleService.instance.toggleLocale(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                size: 15,
                color: activeColor,
              ),
              const SizedBox(width: 5),
              Text(
                'VI',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: !isEn ? FontWeight.w900 : FontWeight.w600,
                  color: !isEn ? activeColor : inactiveColor,
                ),
              ),
              Text(
                ' / ',
                style: TextStyle(
                  fontSize: 11,
                  color: inactiveColor,
                ),
              ),
              Text(
                'EN',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isEn ? FontWeight.w900 : FontWeight.w600,
                  color: isEn ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
