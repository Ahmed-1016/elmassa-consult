import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

class RegionSelectorPage extends StatefulWidget {
  final String cookies;
  final String? token;
  final String? username;
  final String? userId;
  const RegionSelectorPage(
      {super.key,
      required this.cookies,
      required this.token,
      required this.username,
      required this.userId});

  @override
  State<RegionSelectorPage> createState() => _RegionSelectorPageState();
}

class _RegionSelectorPageState extends State<RegionSelectorPage> {
  final http.Client client = http.Client();
  String createPageHtml = '';

  String? token;
  String? selectedGovernorate;
  String? selectedRegionId;
  String? selectedDistrictId;
  String? selectedUnitTypeId;
  String? selectedUnitTypeResponse;
  bool isAreaFieldRequired = false;
  TextEditingController landmarkController = TextEditingController();
  TextEditingController addressDescController = TextEditingController();
  TextEditingController areaController = TextEditingController();

  List<dynamic> regions = [];
  List<dynamic> districts = [];
  final List<Map<String, String>> unitTypes = [
    {'value': '1', 'label': 'وحدة تجاري/إداري/ترفيهي'},
    {'value': '2', 'label': 'وحدة سكني'},
    {'value': '3', 'label': 'مبنى سكني'},
    {'value': '4', 'label': 'مبنى تجاري/إداري/ترفيهي'},
    {'value': '5', 'label': 'شقة دوبلكس سكني'},
    {'value': '6', 'label': 'شقة دوبلكس تجاري/إداري/ترفيهي'},
    {'value': '7', 'label': 'شقة تربلكس سكني'},
    {'value': '8', 'label': 'شقة تربلكس تجاري/إداري/ترفيهي'},
    {'value': '9', 'label': 'شقة كوادر بلكس سكني'},
    {'value': '10', 'label': 'شقة كوادر بلكس تجاري/إداري/ترفيهي'},
    {'value': '11', 'label': 'جراج خاص'},
    {'value': '12', 'label': 'جراج تجاري'},
    {'value': '13', 'label': 'الاراضي المقاسة بالمتر'},
    {'value': '14', 'label': 'الاراضي المقاسة بالفدان'},
    {'value': '16', 'label': 'الفيلا / الشالية بحديقة تجاري/إداري/ترفيهي'},
    {'value': '17', 'label': 'الفيلا / الشالية بالحديقة سكني'},
  ];

  bool isLoadingRegions = false;
  bool isLoadingDistricts = false;
  bool isLoadingUnitType = false;

  int currentStep = 0;
  bool isSubmitting = false;
  int submissionCount = 1; // Number of submissions to make
  int currentSubmission = 0; // Current submission number

  void nextStep() {
    setState(() {
      if (currentStep < 1) currentStep++;
    });
  }

  void previousStep() {
    setState(() {
      if (currentStep > 0) currentStep--;
    });
  }

  @override
  void initState() {
    super.initState();
    loadCreatePage(widget.cookies);
  }

  Future<void> loadCreatePage(String cookieHeader) async {
    try {
      final res = await client.get(
        Uri.parse('https://rsc.mped.gov.eg/UserRequests/Create'),
        headers: {
          'Cookie': cookieHeader,
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://rsc.mped.gov.eg/UserRequests',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (res.statusCode == 200) {
        final html = res.body;
        if (html.contains('RequestsLimit')) {
          final redirectUrl = res.headers['location'] ?? 'غير معروف';
          setState(() {
            createPageHtml = '🔁 تم إعادة التوجيه إلى: $redirectUrl';
          });
          print("createPageHtml: $createPageHtml");
        } else {
          setState(() {
            createPageHtml = html;
          });
          print("Done");
          final document = parse(html);
          final tokenElement = document
              .querySelector('input[name="__RequestVerificationToken"]');
          final verificationToken = tokenElement?.attributes['value'];
          setState(() {
            token = verificationToken;
          });
          print("token: $token");
          if (verificationToken == null) {
            throw Exception("لم يتم العثور على Verification Token");
          }
        }
      } else {
        setState(() {
          createPageHtml = '⚠️ فشل تحميل الصفحة: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        createPageHtml = '⚠️ حصل خطأ أثناء تحميل الصفحة: ${e.toString()}';
      });
    }
  }

  Future<void> submit() async {
    setState(() => isSubmitting = true);
    final headers = {
      'accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'accept-language': 'en-US,en;q=0.9',
      'cache-control': 'max-age=0',
      'content-type': 'application/x-www-form-urlencoded',
      'origin': 'https://rsc.mped.gov.eg',
      'referer': 'https://rsc.mped.gov.eg/UserRequests/Create',
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)...',
      'cookie': widget.cookies,
    };

    final params = {
      'userId': 'UserId',
    };

    final data = {
      'UserId': widget.userId,
      'Createdby': widget.username,
      // 'GovernorateId': selectedGovernorate ?? '',
      // 'Address.RegionId': selectedRegionId ?? '',
      // 'Address.DistrictId': selectedDistrictId ?? '',
      // 'RequestUnitTypeId': selectedUnitTypeId ?? '',
      // 'Address.UniqueMark': landmarkController.text,
      // 'Address.Description': addressDescController.text,
     'GovernorateId': '27',
    'Address.RegionId': '2709',
    'Address.DistrictId': '270901',
    'RequestUnitTypeId': '13',
    'Address.UniqueMark': 'ا',
    'Address.Description': 'ا',
    'BuildingArea': '',
    'LandArea': '',
    'Address.StreetName': '',
    'Address.PropertyNumber': '',
    'Address.FloorNumber': '',
    'Address.FloorNumberText': '',
    'Address.ApartmentNumber': '',
    'Address.EasternBorder': 'ا',
    'Address.MaritimeBorder': 'ا',
    'Address.TribalBorder': 'ا',
    'Address.WesternBorder': 'ا',
    'Address.EasternBorderLength': '1',
    'Address.MaritimeBorderLength': '1',
    'Address.TribalBorderLength': '1',
    'Address.WesternBorderLength': '1',
    'Area': '100',
    'SubUnitTypeArea': '',
    'Price': '1650',
      '__RequestVerificationToken': token,
    };

    try {
      final url = Uri.parse('https://rsc.mped.gov.eg/UserRequests/Create')
          .replace(queryParameters: params);

      final res = await http.post(url, headers: headers, body: data);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ تم إرسال الطلب بنجاح")));
        print(res.body);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ فشل الإرسال - كود ${res.statusCode}")));
        print("Response: ${res.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚫 حصل خطأ أثناء الإرسال")));
      print("Error: $e");
    }

    setState(() => isSubmitting = false);
  }

  Future<void> fetchRegions() async {
    if (selectedGovernorate == null) return;

    setState(() {
      isLoadingRegions = true;
      regions = [];
      selectedRegionId = null;
      districts = [];
      selectedDistrictId = null;
    });

    final uri =
        Uri.parse('https://rsc.mped.gov.eg/UserRequests/GetGovernorateRegions')
            .replace(queryParameters: {'GovernorateId': selectedGovernorate!});

    try {
      final response = await http.get(uri, headers: _buildHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          regions = data;
        });
      } else {
        _showError('حدث خطأ أثناء تحميل المراكز.');
      }
    } catch (e) {
      _showError('فشل الاتصال بالخادم.');
    } finally {
      setState(() => isLoadingRegions = false);
    }
  }

  Future<void> fetchDistricts() async {
    if (selectedRegionId == null) return;

    setState(() {
      isLoadingDistricts = true;
      districts = [];
      selectedDistrictId = null;
    });

    final uri =
        Uri.parse('https://rsc.mped.gov.eg/UserRequests/GetRegionDistricts')
            .replace(queryParameters: {'RegionId': selectedRegionId!});

    try {
      final response = await http.get(uri, headers: _buildHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          districts = data;
        });
      } else {
        _showError('حدث خطأ أثناء تحميل الأحياء.');
      }
    } catch (e) {
      _showError('فشل الاتصال بالخادم.');
    } finally {
      setState(() => isLoadingDistricts = false);
    }
  }

  Future<void> fetchUnitTypeInfo() async {
    if (selectedUnitTypeId == null) return;

    setState(() {
      isLoadingUnitType = true;
      selectedUnitTypeResponse = null;
      isAreaFieldRequired = false;
    });

    final uri =
        Uri.parse('https://rsc.mped.gov.eg/UserRequests/GetSelectedUnitType')
            .replace(queryParameters: {'unitTypeId': selectedUnitTypeId!});

    try {
      final res = await http.get(uri, headers: _buildHeaders());
      if (res.statusCode == 200) {
        final responseText = res.body;
        print(responseText);
        setState(() {
          selectedUnitTypeResponse = responseText;
          try {
            final json = jsonDecode(responseText);
            isAreaFieldRequired = json['inquiryRequestRequired'] == true;
          } catch (e) {
            isAreaFieldRequired = false;
          }
        });
      } else {
        _showError('فشل تحميل بيانات نوع الوحدة.');
      }
    } catch (e) {
      _showError('فشل الاتصال بالخادم.');
    } finally {
      setState(() => isLoadingUnitType = false);
    }
  }

  Map<String, String> _buildHeaders() => {
        'Cookie': widget.cookies,
        'Referer': 'https://rsc.mped.gov.eg/UserRequests/Create',
        'x-requested-with': 'XMLHttpRequest',
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
      };

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار البيانات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (currentStep == 0) ...[
              DropdownButton<String>(
                value: selectedGovernorate,
                hint: const Text('اختر المحافظة'),
                isExpanded: true,
                items: _governorates,
                onChanged: (value) {
                  setState(() => selectedGovernorate = value);
                  fetchRegions();
                },
              ),
              const SizedBox(height: 16),
              if (isLoadingRegions)
                const CircularProgressIndicator()
              else if (regions.isNotEmpty)
                DropdownButton<String>(
                  value: selectedRegionId,
                  hint: const Text('اختر المركز / القسم'),
                  isExpanded: true,
                  items: regions
                      .map<DropdownMenuItem<String>>((r) => DropdownMenuItem(
                            value: r['value'].toString(),
                            child: Text(r['text']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedRegionId = value);
                    fetchDistricts();
                  },
                ),
              const SizedBox(height: 16),
              if (isLoadingDistricts)
                const CircularProgressIndicator()
              else if (districts.isNotEmpty)
                DropdownButton<String>(
                  value: selectedDistrictId,
                  hint: const Text('اختر الحي'),
                  isExpanded: true,
                  items: districts
                      .map<DropdownMenuItem<String>>((d) => DropdownMenuItem(
                            value: d['value'].toString(),
                            child: Text(d['text']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedDistrictId = value);
                  },
                ),
            ] else if (currentStep == 1) ...[
              DropdownButton<String>(
                value: selectedUnitTypeId,
                hint: const Text('اختر نوع الوحدة'),
                isExpanded: true,
                items: unitTypes
                    .map((unit) => DropdownMenuItem(
                          value: unit['value'],
                          child: Text(unit['label']!),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedUnitTypeId = value);
                  fetchUnitTypeInfo();
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: landmarkController,
                decoration: const InputDecoration(
                  labelText: 'أقرب معلم مميز',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressDescController,
                decoration: const InputDecoration(
                  labelText: 'وصف العنوان',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              if (isAreaFieldRequired)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المساحة بالمتر المربع'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: areaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'أدخل المساحة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد المرات',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        submissionCount = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  ElevatedButton(
                    onPressed: previousStep,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black),
                    child: const Text('السابق'),
                  ),
                currentStep == 1
                    ? ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          if (submissionCount > 1) {
                            setState(() {
                              currentSubmission = 0;
                              isSubmitting = true;
                            });
                            for (int i = 0; i < submissionCount; i++) {
                              setState(() => currentSubmission = i + 1);
                              await submit();
                              if (i < submissionCount - 1) {
                                await Future.delayed(const Duration(seconds: 1)); // Add delay between submissions
                              }
                            }
                            setState(() => isSubmitting = false);
                          } else {
                            submit();
                          }
                        },
                        child: isSubmitting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("جاري إنشاء $currentSubmission من $submissionCount..."),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Text('إنشاء'),
                                  if (submissionCount > 1)
                                    Text('($submissionCount مرة)', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                      )
                    : ElevatedButton(
                        onPressed: nextStep,
                        child: const Text('التالي'),
                      ),
              ],
            )
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> get _governorates => const [
        DropdownMenuItem(value: '1', child: Text('القاهرة')),
        DropdownMenuItem(value: '2', child: Text('الإسكندرية')),
        DropdownMenuItem(value: '3', child: Text('بورسعيد')),
        DropdownMenuItem(value: '4', child: Text('السويس')),
        DropdownMenuItem(value: '11', child: Text('دمياط')),
        DropdownMenuItem(value: '12', child: Text('الدقهلية')),
        DropdownMenuItem(value: '13', child: Text('الشرقية')),
        DropdownMenuItem(value: '14', child: Text('القليوبية')),
        DropdownMenuItem(value: '15', child: Text('كفر الشيخ')),
        DropdownMenuItem(value: '16', child: Text('الغربية')),
        DropdownMenuItem(value: '17', child: Text('المنوفية')),
        DropdownMenuItem(value: '18', child: Text('البحيرة')),
        DropdownMenuItem(value: '19', child: Text('الإسماعيلية')),
        DropdownMenuItem(value: '21', child: Text('الجيزة')),
        DropdownMenuItem(value: '22', child: Text('بني سويف')),
        DropdownMenuItem(value: '23', child: Text('الفيوم')),
        DropdownMenuItem(value: '24', child: Text('المنيا')),
        DropdownMenuItem(value: '25', child: Text('أسيوط')),
        DropdownMenuItem(value: '26', child: Text('سوهاج')),
        DropdownMenuItem(value: '27', child: Text('قنا')),
        DropdownMenuItem(value: '28', child: Text('أسوان')),
        DropdownMenuItem(value: '29', child: Text('الأقصر')),
        DropdownMenuItem(value: '31', child: Text('البحر الأحمر')),
        DropdownMenuItem(value: '32', child: Text('الوادي الجديد')),
        DropdownMenuItem(value: '33', child: Text('مطروح')),
        DropdownMenuItem(value: '34', child: Text('شمال سيناء')),
        DropdownMenuItem(value: '35', child: Text('جنوب سيناء')),
      ];
}
