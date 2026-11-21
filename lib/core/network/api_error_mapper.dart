import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stokflow/core/errors/app_exception.dart';

/// Pesan Zod dari backend berbahasa Inggris ("Required"). Jangan tampilkan mentah ke pengguna:
/// petakan ke teks Indonesia dan kunci field ke camelCase nama input aplikasi.
String _indonesianFieldMessage(String zod) {
  if (zod == 'Required') return 'Wajib diisi.';
  if (zod.startsWith('Invalid email')) return 'Email tidak valid.';
  if (zod.startsWith('Invalid uuid')) return 'ID tidak valid.';
  if (zod.contains('at least')) return 'Terlalu pendek.';
  if (zod.contains('at most')) return 'Terlalu panjang.';
  if (zod.startsWith('Expected')) return 'Format tidak sesuai.';
  return 'Tidak valid.';
}

String _camelCase(String path) => path.replaceAllMapped(RegExp(r'_([a-z])'), (m) => m.group(1)!.toUpperCase());

/// `["name: Required", "business_code: Required"]` -> `{name: Wajib diisi., businessCode: Wajib diisi.}`.
/// Elemen tanpa `path: ` diabaikan. Kesalahan pertama per field yang dipakai.
Map<String, String> parseFieldErrors(Iterable<Object?> errors) {
  final result = <String, String>{};
  for (final raw in errors) {
    if (raw is! String) continue;
    final split = raw.indexOf(': ');
    if (split <= 0) continue;
    result.putIfAbsent(_camelCase(raw.substring(0, split)), () => _indonesianFieldMessage(raw.substring(split + 2)));
  }
  return result;
}

/// Envelope backend: `{success, message, data?, errors?[]}`. Fungsi murni agar mudah dites.
AppException mapHttpFailure({required int? statusCode, Object? data}) {
  final body = data is Map<String, dynamic> ? data : const <String, dynamic>{};
  final message = body['message'] is String ? body['message'] as String : null;
  final errors = body['errors'] is List<Object?> ? body['errors'] as List<Object?> : const <Object?>[];

  switch (statusCode) {
    case 400:
      final fields = parseFieldErrors(errors);
      return ValidationException(fields.isNotEmpty ? fields : {'_': message ?? 'Data tidak valid.'});
    case 401:
      return message == null ? const UnauthorizedException() : UnauthorizedException(message);
    case 403:
      return const BusinessInactiveException();
    case 404:
      return message == null ? const NotFoundException() : NotFoundException(message);
    case 409:
      return message == null ? const ConflictException() : ConflictException(message);
    case null || 408 || 429:
      return const NetworkException();
    case >= 500:
      return const NetworkException();
    default:
      return UnexpectedException(message ?? 'Terjadi kesalahan tak terduga.', data);
  }
}

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      return mapHttpFailure(statusCode: e.response?.statusCode, data: e.response?.data);
    case DioExceptionType.cancel:
      return UnexpectedException('Permintaan dibatalkan.', e);
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return e.error is SocketException
          ? const NetworkException()
          : UnexpectedException('Terjadi kesalahan tak terduga.', e);
  }
}

/// Jalankan panggilan Dio dan ubah [DioException] menjadi [AppException].
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e, stack) {
    Error.throwWithStackTrace(mapDioException(e), stack);
  }
}
