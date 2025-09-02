import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class CustomHttpClient {
  final http.Client _client;

  CustomHttpClient()
      : _client = IOClient(HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true);

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(url, headers: headers);
  }

  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _client.post(url, headers: headers, body: body, encoding: encoding);
  }

  void close() {
    _client.close();
  }
}
