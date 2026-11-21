import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/theme/app_colors.dart';
import 'package:stokflow/core/theme/app_theme.dart';

void main() {
  final theme = buildAppTheme();

  test('warna utama dan barang keluar sama dengan mockup', () {
    expect(theme.colorScheme.primary, const Color(0xFF00AA5B));
    expect(theme.colorScheme.secondary, const Color(0xFFFF5C00));
    expect(AppColors.ink, const Color(0xFF0F172A));
  });

  test('target sentuh tombol dan field minimal 44 dp (AGENTS.md)', () {
    expect(kMinTouchTarget, greaterThanOrEqualTo(44));
    expect(theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(44));
    expect(theme.outlinedButtonTheme.style!.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(44));
    expect(theme.textButtonTheme.style!.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(44));
  });

  test('latar aplikasi memakai kanvas abu muda dari mockup', () {
    expect(theme.scaffoldBackgroundColor, AppColors.canvas);
  });
}
