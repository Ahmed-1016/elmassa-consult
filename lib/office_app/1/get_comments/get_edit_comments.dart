import 'dart:convert';
import 'dart:io';
import 'package:ElMassaConsult/utils/http_client.dart';
import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class GetEditComments extends StatefulWidget {
  const GetEditComments({super.key});

  @override
  State<GetEditComments> createState() => _GetEditCommentsState();
}

List<String> loadedRequests = [];
bool _isExporting = false;
String? _currentRequestId;
String? requestNumber;
int _remainingCount = 0;
String? _loadedSheetName;
String? _selectedFileName; // متغير لتخزين اسم الملف

class _GetEditCommentsState extends State<GetEditComments> {
  final CustomHttpClient client = CustomHttpClient();
  String _message = 'اضغط الزر لاختيار ملف';
  bool _isLoading = false;
  bool _isSendingToCompany =
      true; // true for sendingToCompany, false for rejectedToCompany

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  Future<List<String>> readRequestNumbersFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      try {
        final file = File(result.files.single.path!);
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);

        List<String> idNumbers = [];

        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows.skip(1)) {
            final cell = row[0];
            if (cell != null) {
              idNumbers.add(cell.value.toString());
            }
          }
          break; // أول شيت فقط
        }

        _selectedFileName = result.files.single.name; // 👈 اسم الملف
        return idNumbers;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء قراءة الملف')),
          );
        }
        return [];
      }
    } else {
      _selectedFileName = null;
      return [];
    }
  }

  Future<Map<String, String?>> rejectedToCompany(String requestId) async {
    try {
      final params = {
        'workflow': 'raf3_msa7e',
        'lang': 'en-US',
        'sessionid': AppConstant.sissionid,
        'tenant': 'rsc_v2',
        'nodeid': 'form2',
        'id': requestId,
        'tableField': 'NewTable1',
      };

      List<dynamic> allRows = [];
      int currentPage = 1;
      int pageSize = 15;
      int totalRows = 0;

      while (true) {
        final data = jsonEncode({
          "id_shippingorder": requestId,
          "take": pageSize,
          "skip": (currentPage - 1) * pageSize,
          "page": currentPage,
          "pageSize": pageSize,
          "sort": []
        });

        final url = Uri.parse(
                'https://rscapps.edge-pro.com/Workflows/Form/PageTableData')
            .replace(queryParameters: params);

        // Create a custom HttpClient that bypasses certificate verification
        // Create a custom HttpClient that bypasses certificate verification
        final clientFech = HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;

        try {
          final request = await clientFech.postUrl(url);
          request.headers.set('content-type', 'application/json');
          request.headers.set('accept', 'application/json');
          request.write(data);

          final response = await request.close();
          if (response.statusCode != 200) {
            throw Exception('HTTP Error: ${response.statusCode}');
          }

          final responseBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(responseBody);
          final rows = json['data']['rows'] ?? [];
          totalRows = json['data']['totalrowcount'] ?? 0;
          requestNumber = rows[0]['fields']['requestnumber'] ?? '';

          allRows.addAll(rows);
          final totalPages = (totalRows / pageSize).ceil();
          if (currentPage >= totalPages) break;

          currentPage++;
        } finally {
          clientFech.close();
        }
      }

      final details = await getCommentForRequest(requestNumber!);

      final String name = details[11] ?? '';
      final String phoneNumber = details[12] ?? '';
      // Sort comments by time and get the latest one
      if (allRows.isNotEmpty) {
        // Parse date using custom format
        final format = DateFormat('M/d/yyyy h:mm:ss a');
        allRows.sort((a, b) {
          final aTime = format.parse(b['fields']['comment_time']);
          final bTime = format.parse(a['fields']['comment_time']);
          return aTime.compareTo(bTime);
        });

        final latestComment = allRows.first['fields'];
        return {
          'request_id': requestId,
          'request_number': latestComment['requestnumber'] ?? '',
          'name': name,
          'phone_number': phoneNumber,
          'comment': latestComment['comment'] ?? '',
          'comment_time': latestComment['comment_time'] ?? '',
          'user_name': latestComment['user_name'] ?? '',
          'request_type':
              _isSendingToCompany ? 'sendingToCompany' : 'rejectedToCompany',
        };
      }

      return {
        'request_id': requestId,
        'request_number': '',
        'name': '',
        'phone_number': '',
        'comment': 'لا يوجد تعليقات',
        'comment_time': '',
        'user_name': '',
      };
    } catch (e) {
      return {
        'request_id': requestId,
        'request_number': "",
        'name': "",
        'phone_number': "",
        'comment': 'فارغ',
        'comment_time': '',
        'user_name': '',
      };
    }
  }
Future<void> exportToExcel(List<Map<String, String?>> data) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد تعليقات لتصديرها')),
          );
        }
        return;
      }

      final excel = Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet()!;
      excel.rename(defaultSheet, 'التعليقات');
      final sheet = excel['التعليقات'];

      List<String> headers = [
        'مسلسل',
        'رقم الطلب',
        'اسم مقدم الطلب',
        'رقم الهاتف',
        'اسم المستخدم',
        'التعليق',
        'تاريخ التعليق'
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = TextCellValue(row['request_id'] ?? '');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = TextCellValue(row['request_number'] ?? '');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = TextCellValue(row['name'] ?? '');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
            .value = TextCellValue(row['phone_number'] ?? '');

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
            .value = TextCellValue(row['user_name'] ?? '');

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1))
            .value = TextCellValue(row['comment'] ?? '');

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1))
            .value = TextCellValue(row['comment_time'] ?? '');
      }

      final dir = await getApplicationDocumentsDirectory();
      String baseFileName = 'التعليقات_الأخيرة';
      String extension = '.xlsx';
      int counter = 0;
      File file;

      do {
        counter++;
        String fileName = counter == 1
            ? '$baseFileName$extension'
            : '${baseFileName}_$counter$extension';
        file = File('${dir.path}/$fileName');
      } while (await file.exists());

      await file.writeAsBytes(excel.encode()!);

      final result = await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.type == ResultType.done
                  ? 'تم تصدير الملف بنجاح'
                  : 'تم التصدير ولكن لم يتم فتح الملف: ${result.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التصدير: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<String>> getCommentForRequest(String requestId) async {
    try {
      final Map<String, String> headers = {
        'accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'accept-language': 'en-US,en;q=0.9,ar;q=0.8',
        'referer':
            'https://rscapps.edge-pro.com/Workflows/List?workflow=mobile',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/136.0.0.0 Safari/537.36',
      };
      final params = {
        'workflow': 'mobile',
        'lang': 'en-US',
        'sessionid': AppConstant.sissionid,
        'tenant': 'rsc_v2',
        'nodeid': 'form',
        'id': requestId,
      };

      final url = Uri.parse('https://rscapps.edge-pro.com/Workflows/Form')
          .replace(queryParameters: params);

      final response = await client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = response.body;
        final RegExp jsonExtractor =
            RegExp(r'IG\.WorkflowContainer\s*=\s*({.*?});', dotAll: true);
        final match = jsonExtractor.firstMatch(body);

        if (match != null) {
          final jsonString = match.group(1)!;
          final decodedData = jsonDecode(jsonString);
          final List<String> rows = [];

          // Get all rows from the fields array
          final fields =
              decodedData['submodel']['tabs'][0]['groups'][0]['fields'];
          for (var field in fields) {
            if (field['value'] != null) {
              rows.add(field['value'].toString());
            }
          }
          return rows;
        }
      }
      return []; // Return empty list if no data found
    } catch (e) {
      print('Error in getCommentForRequest: $e');
      return []; // Return empty list on error
    }
  }

  Future<Map<String, String>> sendingToCompany(String requestId) async {
    try {
     final headers = {
    'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'accept-language': 'en-US,en;q=0.9,ar;q=0.8',
    'priority': 'u=0, i',
    'referer': 'https://rscapps.edge-pro.com/Workflows/List?workflow=raf3_msa7e&lang=en-US&sessionid=${AppConstant.sissionid}&tenant=rsc_v2&nodeid=list2',
    'sec-ch-ua': '"Not;A=Brand";v="99", "Microsoft Edge";v="139", "Chromium";v="139"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'sec-fetch-dest': 'iframe',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0',
  };

      final params = {
        'workflow': 'raf3_msa7e',
        'lang': 'en-US',
        'sessionid': AppConstant.sissionid,
        'tenant': 'rsc_v2',
        'nodeid': 'form2',
        'id': requestId,
      };
      List<dynamic> allRows = [];

      final url = Uri.parse('https://rscapps.edge-pro.com/Workflows/Form')
          .replace(queryParameters: params);

      final response = await client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        final RegExp jsonExtractor =
            RegExp(r'IG\.WorkflowContainer\s*=\s*({.*?});', dotAll: true);
        final match = jsonExtractor.firstMatch(body);

        if (match != null) {
          final jsonString = match.group(1)!;
          final decodedData = jsonDecode(jsonString);

          final rows = decodedData['submodel']['tabs'][0]['groups'][0]['fields']
                  [2]['data']['rows'] ??
              [];
          requestNumber = decodedData['submodel']['tabs'][0]['groups'][0]
                  ['fields'][0]['fields'][0]['value'] ??
              '';

          allRows.addAll(rows);
        }
      }

      final details = await getCommentForRequest(requestNumber!);

      final String name = details[11] ?? '';
      final String phoneNumber = details[12] ?? '';
      // Sort comments by time and get the latest one
      if (allRows.isNotEmpty) {
        // Parse date using custom format
        final format = DateFormat('M/d/yyyy h:mm:ss a');
        allRows.sort((a, b) {
          final aTime = format.parse(b['fields']['comment_time']);
          final bTime = format.parse(a['fields']['comment_time']);
          return aTime.compareTo(bTime);
        });

        final latestComment = allRows.first['fields'];
        return {
          'request_id': requestId,
          'request_number': requestNumber!,
          'name': name,
          'phone_number': phoneNumber,
          'comment': latestComment['editcertificateinformation'] ?? '',
          'comment_time': latestComment['comment_time'] ?? '',
          'user_name': latestComment['edit_employee'] ?? '',
        };
      }

      return {
        'request_id': requestId,
        'request_number': '',
        'name': '',
        'phone_number': '',
        'comment': 'لا يوجد تعليقات',
        'comment_time': '',
        'user_name': '',
      };
    } catch (e) {
      return {
        'request_id': requestId,
        'request_number': "",
        'name': "",
        'phone_number': "",
        'comment': 'فارغ',
        'comment_time': '',
        'user_name': '',
      };
    }
  }
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعليقات الادارة'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isSendingToCompany ? 'طلبات الإرسال' : 'طلبات مرفوضة التعديل',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Switch(
                            value: _isSendingToCompany,
                            onChanged: (value) {
                              setState(() {
                                _isSendingToCompany = value;
                                _message = _isSendingToCompany
                                    ? 'عرض طلبات الإرسال'
                                    : 'عرض طلبات مرفوضة التعديل';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final requestIds = await readRequestNumbersFromExcel();
                      _selectedFileName = _selectedFileName ?? '';

                      if (requestIds.isNotEmpty) {
                        setState(() {
                          loadedRequests = requestIds;
                          _loadedSheetName = _selectedFileName;
                          _message =
                              'تم تحميل الملف من الشيت "$_loadedSheetName"، اضغط لاستخراج البيانات';
                        });
                      } else {
                        setState(() {
                          _message = 'لم يتم اختيار ملف صالح';
                        });
                      }
                    },
                    icon: const Icon(Icons.file_open),
                    label: const Text('تحميل ملف Excel'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: (loadedRequests.isEmpty || _isExporting)
                        ? null
                        : () async {
                            setState(() {
                              _isExporting = true;
                              _remainingCount = loadedRequests.length;
                            });

                            List<Map<String, String?>> results = [];

                            for (final id in loadedRequests) {
                              setState(() {
                                _currentRequestId = id;
                                _remainingCount =
                                    loadedRequests.length - results.length;
                              });

                              final comment = await (_isSendingToCompany
                                  ? sendingToCompany
                                  : rejectedToCompany)(id);
                              results.add(comment);

                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                            }

                            await exportToExcel(results);

                            setState(() {
                              _isExporting = false;
                              _currentRequestId = null;
                              _remainingCount = 0;
                            });
                          },
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: _isExporting
                        ? Text(
                            'جاري جلب $_currentRequestId (المتبقي: $_remainingCount)')
                        : const Text('استخراج التعليقات'),
                  ),
                ],
              ),
      ),
    );
  }

  
}
