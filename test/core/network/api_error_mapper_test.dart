import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/network/api_error_mapper.dart';

void main() {
  group('parseFieldErrors (format Zod "path: pesan" dari backend)', () {
    test('memetakan Required ke teks Indonesia dan snake_case ke camelCase', () {
      final fields = parseFieldErrors(['name: Required', 'business_code: Required']);

      expect(fields, {'name': 'Wajib diisi.', 'businessCode': 'Wajib diisi.'});
    });

    test('pesan lain dipetakan ke teks Indonesia, tidak pernah menampilkan teks Inggris mentah', () {
      final fields = parseFieldErrors([
        'email: Invalid email',
        'id: Invalid uuid',
        'password: String must contain at least 8 character(s)',
        'name: String must contain at most 5 character(s)',
        'quantity: Expected number, received string',
        'aneh: sesuatu yang tak dikenal',
      ]);

      expect(fields['email'], 'Email tidak valid.');
      expect(fields['id'], 'ID tidak valid.');
      expect(fields['password'], 'Terlalu pendek.');
      expect(fields['name'], 'Terlalu panjang.');
      expect(fields['quantity'], 'Format tidak sesuai.');
      expect(fields['aneh'], 'Tidak valid.');
    });

    test('kesalahan pertama per field dipakai; elemen tanpa path dan non-string diabaikan', () {
      final fields = parseFieldErrors(['name: Required', 'name: Invalid uuid', 'tanpa pemisah', 42, null]);

      expect(fields, {'name': 'Wajib diisi.'});
    });

    test('path bersarang dipertahankan', () {
      expect(parseFieldErrors(['items.0.product_id: Required']), {'items.0.productId': 'Wajib diisi.'});
    });
  });

  group('mapHttpFailure', () {
    test('400 validasi Zod -> ValidationException per field', () {
      final e = mapHttpFailure(
        statusCode: 400,
        data: {
          'success': false,
          'message': 'Validasi input gagal.',
          'errors': ['identifier: Required', 'password: Required'],
        },
      );

      expect(e, isA<ValidationException>());
      expect((e as ValidationException).fieldErrors.keys, ['identifier', 'password']);
    });

    test('400 tanpa field (mis. stok tidak mencukupi) memakai pesan server sebagai kesalahan umum', () {
      final e = mapHttpFailure(statusCode: 400, data: {'message': 'Stok tidak mencukupi', 'errors': <Object?>[]});

      expect((e as ValidationException).fieldErrors, {'_': 'Stok tidak mencukupi'});
    });

    test('401, 403, 404, 409 dipetakan ke exception yang sesuai', () {
      expect(mapHttpFailure(statusCode: 401), isA<UnauthorizedException>());
      expect(mapHttpFailure(statusCode: 403), isA<BusinessInactiveException>());
      expect(mapHttpFailure(statusCode: 404), isA<NotFoundException>());
      expect(mapHttpFailure(statusCode: 409), isA<ConflictException>());
      expect(
        mapHttpFailure(statusCode: 401, data: {'message': 'Identitas atau kata sandi salah.'}).message,
        'Identitas atau kata sandi salah.',
      );
    });

    test('408, 429, 5xx, dan tanpa status dianggap masalah jaringan (coba lagi nanti)', () {
      for (final code in [null, 408, 429, 500, 502, 503]) {
        expect(mapHttpFailure(statusCode: code), isA<NetworkException>(), reason: '$code');
      }
    });

    test('status tak terduga -> UnexpectedException, body non-Map tidak membuat crash', () {
      expect(mapHttpFailure(statusCode: 418, data: 'teks'), isA<UnexpectedException>());
    });
  });

  group('mapDioException dan guardApi', () {
    final options = RequestOptions(path: '/x');

    test('timeout dan connectionError -> NetworkException', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(mapDioException(DioException(requestOptions: options, type: type)), isA<NetworkException>());
      }
    });

    test('badResponse memakai status dan body', () {
      final e = mapDioException(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(requestOptions: options, statusCode: 409, data: {'message': 'Kode bisnis ada'}),
        ),
      );

      expect(e, isA<ConflictException>());
      expect(e.message, 'Kode bisnis ada');
    });

    test('unknown dengan SocketException -> NetworkException; selain itu UnexpectedException', () {
      final socket = DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: const SocketException('putus'),
      );
      final other = DioException(requestOptions: options, type: DioExceptionType.unknown, error: StateError('x'));
      final cancel = DioException(requestOptions: options, type: DioExceptionType.cancel);

      expect(mapDioException(socket), isA<NetworkException>());
      expect(mapDioException(other), isA<UnexpectedException>());
      expect(mapDioException(cancel), isA<UnexpectedException>());
    });

    test('guardApi mengubah DioException menjadi AppException dan meneruskan hasil sukses', () async {
      expect(await guardApi(() async => 42), 42);

      await expectLater(
        guardApi<int>(() => throw DioException(requestOptions: options, type: DioExceptionType.connectionTimeout)),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
