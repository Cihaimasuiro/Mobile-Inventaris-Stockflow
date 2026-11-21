import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/constants/app_config.dart';

void main() {
  test('default: backend produksi di /api (bukan /api/v1), timeout 15 dtk, ticker sync 30 dtk', () {
    final config = AppConfig.fromEnvironment();

    expect(config.apiBaseUrl, 'https://stokflow-be.vercel.app/api');
    expect(config.apiBaseUrl, isNot(contains('/v1')));
    expect(config.requestTimeout, const Duration(seconds: 15));
    expect(config.syncInterval, const Duration(seconds: 30));
  });
}
