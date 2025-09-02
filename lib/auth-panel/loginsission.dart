import 'dart:io';
import 'dart:convert';
import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:http/http.dart' as http;



class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> fetchSessionId({String username = 'masa1', String password = 'FWE@ert#m'}) async {
  try {
    HttpOverrides.global = MyHttpOverrides();

    final headers = {
      'accept': '*/*',
      'content-type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'origin': 'https://rscapps.edge-pro.com',
      'referer': 'https://rscapps.edge-pro.com/Apps/?tenant=rsc_v2',
      'tenant': 'rsc_v2',
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0',
    };

    final data = {
      'grant_type': 'password',
      'username': username,
      'password': password,
      'client_id': 'App',
    };

    final url = Uri.parse('https://rscapps.edge-pro.com/api/v1/oauth2/token');

    final res = await http.post(url, headers: headers, body: data);

    if (res.statusCode != 200) {
      throw Exception(
          'http.post error: statusCode= ${res.statusCode}\n${res.body}');
    }

    // نفك JSON ونجيب الـ sessionId
    final jsonData = json.decode(res.body);
    final sessionId = jsonData["sessionId"]?.toString();

    // تخزينه في الكلاس
    AppConstant.sissionid = sessionId;

  } catch (e) {
    print("❌ Error: $e");
  }
}
