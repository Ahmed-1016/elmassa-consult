// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'utils/http_client.dart';
import 'package:flutter/services.dart'; // Import clipboard package

class GetOrdersIndecto extends StatefulWidget {
  const GetOrdersIndecto({Key? key}) : super(key: key);

  @override
  State<GetOrdersIndecto> createState() => _GetOrdersIndectoState();
}

List<String> loadedRequests = [];
bool _isExporting = false;
String? _currentRequestId;
int _remainingCount = 0; // متغير لحساب عدد الطلبات المتبقية

class _GetOrdersIndectoState extends State<GetOrdersIndecto> {
  String _message = 'اضغط الزر لاختيار ملف';
  bool _isLoading = false;
  late CustomHttpClient _client;
  List<Map<String, String?>> _comments = []; // List to store comments

  @override
  void initState() {
    super.initState();
    _client = CustomHttpClient();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

   final headers = {
      'accept': 'application/json, text/javascript, */*; q=0.01',
      'accept-language': 'en-US,en;q=0.9',
      'content-type': 'application/json; charset=UTF-8',
      'origin': 'https://rscapps.edge-pro.com',
      'priority': 'u=1, i',
      'referer':
          'https://rscapps.edge-pro.com/Workflows/List?workflow=surveyteams&lang=en-US&sessionid=f11195e0-eb00-4783-8d7d-435b2ff2b82a&tenant=rsc_v2&nodeid=assigned_tasks_surv',
      'sec-ch-ua':
          '"Google Chrome";v="135", "Not-A.Brand";v="8", "Chromium";v="135"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36',
      'x-requested-with': 'XMLHttpRequest',
    };

  Future<Map<String, String?>> getCommentForRequest(String requestId) async {
    try {

        final params = {
      'workflow': 'surveyteams',
      'lang': 'en-US',
      'sessionid': 'f11195e0-eb00-4783-8d7d-435b2ff2b82a',
      'tenant': 'rsc_v2',
      'nodeid': 'assigned_tasks_surv',
      'id': requestId,
    };

      final url = Uri.parse('https://rscapps.edge-pro.com/Workflows/List/PageData')
          .replace(queryParameters: params);

      final response = await _client.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = response.body;
     
          final jsonString = body;
          final decodedData = jsonDecode(jsonString);
          final rows = decodedData['submodel']['tabs'][4]['groups'][0]['fields']
              [1]['value'];
          
          // Format the timestamp
          final timestamp = DateTime.now().toString();
          
          return {
            'request_id': requestId,
            'comment': rows,
            'comment_time': timestamp
          };
        
      }
      return {
        'request_id': requestId,
        'comment': 'لا يوجد تعليق',
        'comment_time': DateTime.now().toString()
      };
    } catch (e) {
      print('Error fetching comment for request $requestId: $e');
      return {
        'request_id': requestId,
        'comment': 'حدث خطأ أثناء جلب التعليق',
        'comment_time': DateTime.now().toString()
      };
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعليقات الادارة')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_message),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'أدخل رقم الطلب',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          loadedRequests = [value];
                          _message = 'تم تحميل رقم الطلب';
                        });
                      }
                    },
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

                              final comment = await getCommentForRequest(id);
                              results.add(comment);

                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                            }

                            setState(() {
                              _isExporting = false;
                              _currentRequestId = null;
                              _remainingCount = 0;
                              _comments = results; // Store results in state
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
                  const SizedBox(height: 20),
                  // Add ListView to display comments
                  Expanded(
                    child: _comments.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'رقم الطلب: ${comment['request_id']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'التعليق: ${comment['comment']}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy),
                                            onPressed: () {
                                              final commentText = comment['comment'] ?? '';
                                              Clipboard.setData(
                                                ClipboardData(text: commentText),
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('تم نسخ التعليق'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'التاريخ: ${comment['comment_time']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
