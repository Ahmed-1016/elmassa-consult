// ignore_for_file: avoid_print
import 'dart:io';
import 'package:ElMassaConsult/auth-panel/welcome-screen.dart';
import 'package:ElMassaConsult/site_app/general/categories_site_screen.dart';
import 'package:ElMassaConsult/utils/text_animation_widget.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiteGovScreenWindows extends StatefulWidget {
  final String? userName;

  const SiteGovScreenWindows({super.key, this.userName});

  @override
  State<SiteGovScreenWindows> createState() => _SiteGovScreenWindowsState();
}

class _SiteGovScreenWindowsState extends State<SiteGovScreenWindows> {
  final List<String> governorates = [
    "محافظة أسوان",
    "محافظة الأقصر",
    "محافظة قنا",
    "محافظة سوهاج",
    "محافظة أسيوط",
    "محافظة القاهرة",
    "محافظة المنيا",
    "محافظة الجيزة",
    "محافظة الغربية"
  ];

  late final User? user = FirebaseAuth.instance.currentUser;

  List<QueryDocumentSnapshot> teamWorkCodeDocuments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFirestoreData();
  }

  String? selectedTeamWorkCodeId;

  Future<void> _loadFirestoreData() async {
    try {
      final [teamWorkCodeResult] = await Future.wait([
        FirebaseFirestore.instance.collection('siteTeamWorkCodes').get(),
      ]);

      setState(() {
        teamWorkCodeDocuments = teamWorkCodeResult.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar(
        "خطأ",
        "فشل في تحميل البيانات",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    return hour >= 1 && hour < 12 ? 'صباح الخير' : 'مساء الخير';
  }

  void _handleGovernorateTap(String governorate) async {
    if (isLoading) return;

    String? selectedTeamWorkCodeId;

    AwesomeDialog(
      width: (!kIsWeb && Platform.isAndroid) ? null : Get.width / 2,
      context: context,
      dialogType: DialogType.info,
      title: "تأكيد الإجراء",
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading || teamWorkCodeDocuments.isEmpty
            ? const Text("لا توجد بيانات متاحة")
            : Column(
                children: [
                  _buildDropdown(
                    label: "برجاء اختيار الكود",
                    items: teamWorkCodeDocuments,
                    value: selectedTeamWorkCodeId,
                    onChanged: (value) {
                      setState(() {
                        selectedTeamWorkCodeId = value;
                      });
                    },
                  ),
                ],
              ),
      ),
      btnCancelOnPress: () {
        Get.back(closeOverlays: true);
      },
      btnCancelText: 'إلغاء',
      btnOkOnPress: () async {
        if (selectedTeamWorkCodeId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userCode', selectedTeamWorkCodeId!);
          await prefs.setString('govName', governorate);
          Get.to(
            () => CategoriesSiteScreen(
              govName: governorate,
              userName: widget.userName!,
              userCode: selectedTeamWorkCodeId!,
            ),
          );
          print(' widget.governorate!: $governorate');
          print(' widget.userName!: ${widget.userName!}');
          print(' widget.selectedTeamWorkCodeId!: ${selectedTeamWorkCodeId!}');
         
        } else {
          Get.snackbar(
            "خطأ",
            "برجاء اختيار البيانات الصحيحة",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
      btnOkText: 'تأكيد',
    ).show();
  }

  Widget _buildDropdown({
    required String label,
    required List<QueryDocumentSnapshot> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((doc) {
        return DropdownMenuItem<String>(
          value: doc.id,
          child: Text(
            doc.id,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color.fromARGB(255, 90, 4, 58),
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
      actions: [_buildLogoutButton()],
      centerTitle: true,
      backgroundColor: Colors.white,
      title: const Text('منظومة شركة الماسة كونسلت'),
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

  Widget _buildGovernorateGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: governorates.length,
        itemBuilder: (context, index) => GovernorateCard(
          name: governorates[index],
          onTap: () => _handleGovernorateTap(governorates[index]),
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
        elevation: 4,
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
