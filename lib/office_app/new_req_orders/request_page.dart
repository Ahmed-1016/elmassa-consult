// login_page.dart
import 'package:ElMassaConsult/office_app/new_req_orders/region_selector.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? extractedUsername;
  String? extractedUserId;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String? loginStatus;
  String? token;
  String? cookies;
  bool loading = false;

  final client = http.Client();

  Future<void> login() async {
    setState(() {
      loading = false;
      loginStatus = '';
      token = '';
      cookies = '';
    });

    final loginUrl =
        Uri.parse('https://rsc.mped.gov.eg/Identity/Account/Login');

    try {
      final loginPageResponse = await client.get(loginUrl);
     
      final cookieHeader = loginPageResponse.headers['set-cookie'] ?? '';
      final antiforgeryCookie = extractAntiforgeryCookies(cookieHeader);
      String cultureCookie = ".AspNetCore.Culture=c%3Dar-EG%7Cuic%3Dar-EG";
      String cleanedCookieHeader = antiforgeryCookie + " $cultureCookie";

      final document = parse(loginPageResponse.body);
      final tokenElement =
          document.querySelector('input[name="__RequestVerificationToken"]');
      final verificationToken = tokenElement?.attributes['value'];
      if (verificationToken == null) {
        throw Exception("لم يتم العثور على Verification Token");
      }

      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': cleanedCookieHeader,
        'Referer': loginUrl.toString(),
        'User-Agent': 'Mozilla/5.0',
      };

      final body = {
        '__RequestVerificationToken': verificationToken,
        'Input.UserName': usernameController.text.trim(),
        'Input.Password': passwordController.text.trim(),
        'Input.RememberMe': 'false',
      };

      final response = await client.post(
        loginUrl,
        headers: headers,
        body: body,
      );
      final responseCookies = response.headers['set-cookie'] ?? '';
  
      if (response.statusCode == 302 || response.body.contains('تسجيل الخروج')) {
        try {
          final identityCookie = extractIdentityCookie(responseCookies);
          final allCookies = "$cleanedCookieHeader; $identityCookie";

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ تسجيل الدخول تم بنجاح"),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            token = verificationToken;
            cookies = allCookies;
          });

          await loadHomePage(cookies!);

        } catch (e) {
          setState(() {
            loginStatus = "❌ فشل في تحميل الصفحة الرئيسية: $e";
          });
        }
      }
    } catch (e) {
      setState(() {
        loginStatus = "⚠️ خطأ: $e";
      });
    } finally {
      setState(() {
        loading = true;
      });
    }
  }

  Future<void> loadHomePage(String cookieHeader) async {
    try {
      final requestUri = Uri.parse('https://rsc.mped.gov.eg/');

      // Prepare headers
      final headers = {
        'accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'accept-language': 'en-US,en;q=0.9,ar;q=0.8',
        'cache-control': 'max-age=0',
        'priority': 'u=0, i',
        'referer': 'https://rsc.mped.gov.eg/Identity/Account/Login',
        'sec-ch-ua':
            '"Microsoft Edge";v="137", "Chromium";v="137", "Not/A)Brand";v="24"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'sec-fetch-dest': 'document',
        'sec-fetch-mode': 'navigate',
        'sec-fetch-site': 'same-origin',
        'sec-fetch-user': '?1',
        'upgrade-insecure-requests': '1',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0',
        'cookie': cookieHeader,
      };


      final response = await client.get(requestUri, headers: headers);
      if (response.statusCode == 200) {
        final document = parse(response.body);
        // Extract username
        final usernameElement = document.querySelector('p.mx-2.my-auto');
        final username = usernameElement?.text.trim() ?? '';

        // Extract user ID from profile link
        final profileLink = document.querySelector('a#User-Profiles');
        String? userId;
        if (profileLink != null) {
          final href = profileLink.attributes['href'];
          final uri = Uri.parse(href!);
          userId = uri.queryParameters['userId'];
        }

        // Store them in state
        setState(() {
          extractedUsername = username;
          extractedUserId = userId;
        });
        print('Username: $username'); // 123@Yaseertla3t
        print('User ID: $userId'); // c5304e26-e1dd-415c-9271-3d65e14a61cc

        // Navigate to RegionSelectorPage after successful login
        if (username.isNotEmpty && userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegionSelectorPage(
                cookies: cookies!,
                token: token,
                username: extractedUsername!,
                userId: extractedUserId!,
              ),
            ),
          );
        }
      } else {
        setState(() {
          loginStatus = '❌ فشل تحميل الصفحة الرئيسية: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        loginStatus = '⚠️ حصل خطأ أثناء تحميل الصفحة: ${e.toString()}';
      });
    } finally {
      setState(() {
        loading = true;
      });
    }
  }

  String extractAntiforgeryCookies(String cookieString) {
    final antiforgery = RegExp(r'(\.AspNetCore\.Antiforgery\.[^=]+=[^;]+;)')
        .firstMatch(cookieString)
        ?.group(1);

    return antiforgery!;
  }

  String extractIdentityCookie(String cookieString) {
    final match = RegExp(r'\.AspNetCore\.Identity\.Application=([^;]+)')
        .firstMatch(cookieString);
    return match!.group(0)!; // يرجع السطر كامل بـ key=value
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل الدخول")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "اسم المستخدم"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "كلمة المرور"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: login,
              icon: const SizedBox(
                  width: 18, height: 18, child: Icon(Icons.login)),
              label: const Text("تسجيل الدخول"),
            ),
            const SizedBox(height: 20),
            if (loginStatus != null)
              Text(
                loginStatus!,
                style: TextStyle(
                  color:
                      loginStatus!.startsWith("✅") ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
