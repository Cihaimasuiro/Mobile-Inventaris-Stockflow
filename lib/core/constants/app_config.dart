/// Konfigurasi runtime lewat `--dart-define` (tanpa file `.env` di bundle aplikasi).
/// Kunci sama dengan `.env.example`:
///
///   flutter run --dart-define=API_BASE_URL=https://stokflow-be.vercel.app/api
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.requestTimeout, required this.syncInterval});

  factory AppConfig.fromEnvironment() => const AppConfig(
    apiBaseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: defaultApiBaseUrl),
    requestTimeout: Duration(milliseconds: int.fromEnvironment('REQUEST_TIMEOUT_MS', defaultValue: 15000)),
    syncInterval: Duration(seconds: int.fromEnvironment('OFFLINE_SYNC_INTERVAL_SEC', defaultValue: 30)),
  );

  /// Backend produksi. Path API: `/api/...` (BUKAN `/api/v1`); `/health` ada di root.
  static const String defaultApiBaseUrl = 'https://stokflow-be.vercel.app/api';

  final String apiBaseUrl;
  final Duration requestTimeout;

  /// Interval ticker sync latar belakang.
  final Duration syncInterval;
}
