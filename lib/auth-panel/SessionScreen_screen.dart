import 'package:ElMassaConsult/models/Qrcode_sign_in_model.dart';
import 'package:ElMassaConsult/office_app/general/admin_screen_windows.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen_windows.dart';
import 'package:ElMassaConsult/controllers/generate-qr-id-services.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen_windows.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  String? _currentToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateNewToken(); // إنشاء الباركود عند فتح الشاشة
  }

  Future<void> _generateNewToken() async {
    setState(() => _isLoading = true);

    final token = generateQrId();
    final qrCodeData = QrCodeSignInModel(
        status: 'pending',
        expiresAt: DateTime.now().add(Duration(minutes: 5)),
        userId: "null",
        userName: "",
        typeApp: "",
        selectedCategory: '');

    await FirebaseFirestore.instance
        .collection('computer_sessions')
        .doc(token)
        .set(qrCodeData.toMap());

    setState(() {
      _currentToken = token;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(centerTitle: true, title: const Text('Login With QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentToken != null) ...[
              QrImageView(
                data: _currentToken!,
                size: 200,
              ),
              const SizedBox(height: 20),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('computer_sessions')
                    .doc(_currentToken)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data!;
                    String userName = data['userName'];
                    String selectedCategory = data['selectedCategory'];
                    if (data['status'] == 'completed') {
                      // إذا تم تحديث الحالة إلى "completed"
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (selectedCategory == 'موقع') {
                          Get.offAll(() => SiteGovScreenWindows(
                                userName: userName,
                              ));
                        } else if (selectedCategory == 'مكتب فنى') {
                          if (userName == "Admin") {
                            Get.offAll(
                                () => AdminScreenWindows(userName: userName));
                          } else {
                            Get.offAll(() =>
                                OfficeGovScreenWindows(userName: userName));
                          }
                        }
                      });
                    }
                  }
                  return const Text(
                    'بانتظار المسح...',
                    style: TextStyle(color: Colors.blue),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateNewToken,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('إنشاء باركود جديد'),
            ),
          ],
        ),
      ),
    );
  }
}
