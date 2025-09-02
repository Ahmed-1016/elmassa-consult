// ignore_for_file: use_build_context_synchronously, avoid_print, unused_element

import 'dart:io';

import 'package:ElMassaConsult/auth-panel/welcome-screen.dart';
import 'package:ElMassaConsult/office_app/1/excel_export_screen.dart';
import 'package:ElMassaConsult/office_app/general/all_performance_rates_screen.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen_windows.dart';
import 'package:ElMassaConsult/office_app/general/import_from_excel.dart';
import 'package:ElMassaConsult/office_app/general/performance_rates_screen.dart';
import 'package:ElMassaConsult/office_app/general/rates_and_numbers.dart';
import 'package:ElMassaConsult/utils/text_animation_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';

class AdminScreenWindows extends StatefulWidget {
  final String? userName;
  const AdminScreenWindows({super.key, this.userName});

  @override
  State<AdminScreenWindows> createState() => _AdminScreenWindowsState();
}

class _AdminScreenWindowsState extends State<AdminScreenWindows> {
  final List<String> mainList = [
    "المحافظات",
    "احصاءات",
    "اخراج شيت اكسيل من التطبيق",
    " معدلات الأداء",
    "الاداء العام",


  ];

  late final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _nameController = TextEditingController();
  @override
  void dispose() {
    _nameController;
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    return hour >= 1 && hour < 12 ? 'صباح الخير' : 'مساء الخير';
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
            _buildMainListGrid(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: !kIsWeb && Platform.isAndroid ? null : _addIconButton(),
      actions: [_buildLogoutButton()],
      centerTitle: true,
      backgroundColor: Colors.white,
      title: const Text('منظومة شركة الماسة كونسلت'),
    );
  }
Widget _addIconButton() {
  return IconButton(
    icon: const Icon(Icons.add, size: 35),
    onPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ImportExcelPage()),
      );
    },
  );
}


  Widget _buildLogoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        // تسجيل الخروج فقط إذا لم يكن ويب ولم يكن ويندوز
        if (!kIsWeb) {
          // Platform.isWindows متاح فقط إذا لم يكن ويب
          if (!Platform.isWindows) {
            await FirebaseAuth.instance.signOut();
            await GoogleSignIn.instance.signOut();
          }
        }
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

  Widget _buildMainListGrid() {
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
          childAspectRatio: 4,
        ),
        itemCount: mainList.length,
        itemBuilder: (context, index) => MainListCard(
          name: mainList[index],
          onTap: () {
            switch (index) {
              case 0:
                Get.to(() => OfficeGovScreenWindows(userName: widget.userName));
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
              default:
            }
          },
        ),
      ),
    );
  }
}

class MainListCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const MainListCard({
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
