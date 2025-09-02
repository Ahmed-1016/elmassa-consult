import 'dart:io';

import 'package:ElMassaConsult/auth-panel/welcome-screen.dart';
import 'package:ElMassaConsult/office_app/1/excel_export_screen.dart';
import 'package:ElMassaConsult/office_app/general/all_performance_rates_screen.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen.dart';
import 'package:ElMassaConsult/office_app/general/performance_rates_screen.dart';
import 'package:ElMassaConsult/office_app/general/rates_and_numbers.dart';

import 'package:ElMassaConsult/utils/text_animation_widget.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';

class AdminScreen extends StatefulWidget {
  final String userName;
  final String selectedCategory;
  const AdminScreen({super.key, required this.userName, required this.selectedCategory});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final List<String> mainList = [
    "المحافظات",
    "احصاءات",
    "اخراج شيت اكسيل من التطبيق",
    " معدلات الأداء",
    "الاداء العام",
     
  ];

  late final User? user = FirebaseAuth.instance.currentUser;
  List<QueryDocumentSnapshot> teamWorkCodeDocuments = [];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    return hour >= 1 && hour < 12 ? 'صباح الخير' : 'مساء الخير';
  }

  Future<void> _clearStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedCategory');
    await prefs.remove('selectedUsername');
    await prefs.remove('enteredPassword');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        color: const Color.fromARGB(255, 126, 39, 10),
        child: ListView(
          children: [
            _buildHeader(),
            _buildGovernorateGrid(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: _scanIconButton(),
      actions: [_buildLogoutButton()],
      centerTitle: true,
      backgroundColor: Colors.white,
      title: const Text('منظومة شركة الماسة كونسلت'),
    );
  }

  Widget _scanIconButton() {
    return IconButton(
      icon: const Icon(Icons.qr_code_scanner, size: 35),
      onPressed: () {
        AwesomeDialog(
            context: context,
            dialogType: DialogType.noHeader,
            animType: AnimType.scale,
            dismissOnTouchOutside: true,
            dismissOnBackKeyPress: true,
            body: SizedBox(
              height: 300, // تحديد ارتفاع مربع الحوار
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        // إغلاق مربع الحوار
                        _handleScannedToken(barcode.rawValue!);
                        Get.back();
                        // التعامل مع التوكن الممسوح
                        break;
                      }
                    }
                  },
                ),
              ),
            )).show();
      },
    );
  }

  bool _isProcessing = false;
  void _handleScannedToken(String token) async {
    if (_isProcessing) return; // منع التكرار
    _isProcessing = true;

    try {
      final sessionDoc = await FirebaseFirestore.instance
          .collection('computer_sessions')
          .doc(token)
          .get();

      if (sessionDoc.exists && sessionDoc['status'] == 'pending') {
        await sessionDoc.reference.update({
          'status': 'completed',
          'userName': widget.userName,
          'selectedCategory': widget.selectedCategory
        });
        Get.snackbar(
          "نجاح",
          "تم تحديث الحالة إلى 'completed'",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "خطأ",
          "الرمز غير صالح أو الحالة ليست 'pending'",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "حدث خطأ أثناء معالجة الرمز",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isProcessing = false;
    }
  }

  Widget _buildLogoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await _clearStoredCredentials();
        await FirebaseAuth.instance.signOut();
        Platform.isWindows ? null : await GoogleSignIn.instance.signOut();
        Get.offAll(() => WelcomeScreen());
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        _buildGreeting(),
        _buildCompanyBanner(),
      ],
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Text(
            "${_getGreeting()}،  ",
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          Text(
            user?.displayName ?? "",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.waving_hand, color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildCompanyBanner() {
    return Get.width > 600 ? _buildDesktopBanner() : _buildMobileBanner();
  }

  Widget _buildDesktopBanner() {
    return Container(
      height: 200,
      decoration: _bannerDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/elmassa_logo.png'),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'El Massa Consult',
                  style: TextStyle(
                    fontSize: 40,
                    color: Color(0xFF7F0202),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextAnimationWidget(),
                WidgetAnimator(
                  incomingEffect:
                      WidgetTransitionEffects.incomingSlideInFromBottom(),
                  atRestEffect: WidgetRestingEffects.swing(),
                  child: const Icon(
                    Icons.arrow_circle_down_outlined,
                    size: 50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBanner() {
    return Container(
      height: 120,
      decoration: _bannerDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/elmassa_logo.png'),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'El Massa Consult',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFF9A0101),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '.A place you trust',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF212B60),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _bannerDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Colors.blue, Color(0xFFF78981)],
      ),
    );
  }

  Widget _buildGovernorateGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: mainList.length,
        itemBuilder: (context, index) => GovernorateCard(
          name: mainList[index],
          onTap: () {
            switch (index) {
              case 0:
                Get.to(() => OfficeGovScreen(userName: widget.userName));
                break;
              case 1:
                Get.to(() => RatesAndNumbers(userName: widget.userName));
                break;
             
              case 2:
                Get.to(() => const ExcelExportScreen());
                break;

              case 3:
                Get.to(() => const PerformanceDashboard());
                break;
              case 4:
                Get.to(() => const AllPerformanceRatesScreen());
                break;
          
            
              // case 5:
              //   Get.to(() => const PerformanceRatesScreen());
              //   break;
              default:
            }
          },
        ),
      ),
    );
  }
}

class GovernorateCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const GovernorateCard({
    super.key,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 10,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 25,
            ),
          ),
        ),
      ),
    );
  }
}
