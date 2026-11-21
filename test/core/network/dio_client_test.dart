import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/constants/app_config.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/network/api_error_mapper.dart';
import 'package:stokflow/core/network/dio_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.status = 200, this.body = '{"success":true}'});

  final int status;
  final String body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _config = AppConfig(
  apiBaseUrl: 'https://api.test/api',
  requestTimeout: Duration(seconds: 7),
  syncInterval: Duration(seconds: 30),
);

void main() {
  test('menggabungkan base URL dengan path berawalan "/" dan menyisipkan Bearer token', () async {
    final adapter = _FakeAdapter();
    final dio = createDio(config: _config, readToken: () async => 'abc.def.ghi', adapter: adapter);

    await dio.get<Object?>('/products');

    expect(adapter.last!.uri.toString(), 'https://api.test/api/products');
    expect(adapter.last!.headers['Authorization'], 'Bearer abc.def.ghi');
    expect(adapter.last!.headers['Accept'], 'application/json');
  });

  test('tanpa token (belum login atau kosong) tidak ada header Authorization', () async {
    for (final token in <String?>[null, '']) {
      final adapter = _FakeAdapter();
      final dio = createDio(config: _config, readToken: () async => token, adapter: adapter);

      await dio.post<Object?>('/auth/login', data: {'identifier': 'x'});

      expect(adapter.last!.headers.containsKey('Authorization'), isFalse, reason: 'token=$token');
    }
  });

  test('timeout mengikuti konfigurasi', () {
    final dio = createDio(config: _config, readToken: () async => null);

    expect(dio.options.connectTimeout, const Duration(seconds: 7));
    expect(dio.options.receiveTimeout, const Duration(seconds: 7));
  });

  test('respons 401 dari backend menjadi UnauthorizedException lewat guardApi', () async {
    final adapter = _FakeAdapter(
      status: 401,
      body: '{"success":false,"message":"Token otentikasi tidak valid.","errors":["jwt malformed"]}',
    );
    final dio = createDio(config: _config, readToken: () async => 'x', adapter: adapter);

    await expectLater(guardApi(() => dio.get<Object?>('/sync/pull')), throwsA(isA<UnauthorizedException>()));
  });

  test('respons 400 Zod menjadi ValidationException berisi field', () async {
    final adapter = _FakeAdapter(
      status: 400,
      body: '{"success":false,"message":"Validasi input gagal.","errors":["identifier: Required"]}',
    );
    final dio = createDio(config: _config, readToken: () async => null, adapter: adapter);

    await expectLater(
      guardApi(() => dio.post<Object?>('/auth/login', data: <String, dynamic>{})),
      throwsA(isA<ValidationException>().having((e) => e.fieldErrors['identifier'], 'identifier', 'Wajib diisi.')),
    );
  });
}
