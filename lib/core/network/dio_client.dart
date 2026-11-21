import 'package:dio/dio.dart';
import 'package:stokflow/core/constants/app_config.dart';

/// Membaca token JWT saat ini (dari secure storage). `null` = belum login.
typedef TokenReader = Future<String?> Function();

/// Menyisipkan `Authorization: Bearer <jwt>`. Server mengambil `business_id` dari token,
/// jadi klien tidak pernah mengirim `business_id` di body.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._readToken);

  final TokenReader _readToken;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Dio untuk Stockflow API. Path pada request diawali `/` (mis. `/auth/login`).
/// Ubah error lewat `guardApi` di `api_error_mapper.dart`, bukan di interceptor.
Dio createDio({required AppConfig config, required TokenReader readToken, HttpClientAdapter? adapter}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.requestTimeout,
      sendTimeout: config.requestTimeout,
      receiveTimeout: config.requestTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  )..interceptors.add(AuthInterceptor(readToken));
  if (adapter != null) dio.httpClientAdapter = adapter;
  return dio;
}
