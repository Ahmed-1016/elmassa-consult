import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AllPerformanceRatesScreen extends StatefulWidget {
  const AllPerformanceRatesScreen({super.key});

  @override
  State<AllPerformanceRatesScreen> createState() => _AllPerformanceRatesScreenState();
}

class _AllPerformanceRatesScreenState extends State<AllPerformanceRatesScreen> {
  bool isLoading = true;
  String userType = 'عام';
  Map<String, int> allStageCounts = {};
  Map<String, int> allDateCounts = {};

  @override
  void initState() {
    super.initState();
    loadAllPerformances();
  }

  Future<void> loadAllPerformances() async {
    try {
      setState(() {
        allStageCounts.clear();
        allDateCounts.clear();
      });

      List<QueryDocumentSnapshot> allUsers = [];

      if (userType == 'عام' || userType == 'المكتب الفني') {
        final officeUsers = await FirebaseFirestore.instance.collection('PrOfficeTeamWork').get();
        allUsers.addAll(officeUsers.docs);
      }
      if (userType == 'عام' || userType == 'الموقع') {
        final siteUsers = await FirebaseFirestore.instance.collection('PrSiteTeamWork').get();
        allUsers.addAll(siteUsers.docs);
      }

      for (var userDoc in allUsers) {
        final perRateSnapshot = await userDoc.reference.collection('PerRate').get();

        for (var doc in perRateSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final stage = data['orderStatus'] ?? 'غير معروف';
          final createdOn = (data['createdOn'] as Timestamp).toDate();
          final dayKey = DateFormat('yyyy-MM-dd').format(createdOn);

          allStageCounts[stage] = (allStageCounts[stage] ?? 0) + 1;
          allDateCounts[dayKey] = (allDateCounts[dayKey] ?? 0) + 1;
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('حدث خطأ: $e');
      setState(() => isLoading = false);
    }
  }

  Color _colorForStage(String stage) {
    switch (stage) {
      case 'Stage 1':
        return const Color.fromARGB(255, 255, 191, 0);
      case 'Stage 2':
        return const Color.fromARGB(255, 0, 140, 254);
      case 'Stage 3':
        return const Color.fromARGB(255, 0, 255, 8);
      case 'تم الرسم':
        return const Color.fromARGB(255, 247, 27, 101);
      case 'تم التسليم':
        return const Color.fromARGB(255, 77, 248, 140);
      case 'تم الرفع':
        return const Color.fromARGB(255, 221, 172, 230);
      case 'تعذر الرفع':
        return const Color.fromARGB(255, 6, 255, 214);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last30Days = List.generate(30, (i) {
      final day = today.subtract(Duration(days: 29 - i));
      return DateFormat('yyyy-MM-dd').format(day);
    });

    final dateCountsForLast30Days = <String, int>{};
    for (var day in last30Days) {
      dateCountsForLast30Days[day] = allDateCounts[day] ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الأداء الإجمالية'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                
                value: userType,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                style: const TextStyle(color: Colors.black),
                items: const [
                  DropdownMenuItem(value: 'عام', child: Text('عام')),
                  DropdownMenuItem(value: 'المكتب الفني', child: Text('المكتب الفني')),
                  DropdownMenuItem(value: 'الموقع', child: Text('الموقع')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      userType = value;
                      isLoading = true;
                    });
                    loadAllPerformances();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مخطط جميع المراحل',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: allStageCounts.entries.map((e) {
                          final color = _colorForStage(e.key);
                          return BarChartGroupData(
                            x: allStageCounts.keys.toList().indexOf(e.key),
                            barRods: [
                              BarChartRodData(toY: e.value.toDouble(), color: color, width: 20),
                            ],
                            showingTooltipIndicators: [0],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (index < allStageCounts.length) {
                                  return Text(
                                    allStageCounts.keys.elementAt(index),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('المخطط الزمني',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: List.generate(dateCountsForLast30Days.length, (index) {
                              final day = last30Days[index];
                              final count = dateCountsForLast30Days[day]!;
                              return FlSpot(index.toDouble(), count.toDouble());
                            }),
                            barWidth: 2,
                            color: Colors.teal,
                            dotData: FlDotData(show: true),
                          )
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (index >= 0 && index < last30Days.length) {
                                  final parts = last30Days[index].split('-');
                                  return Text('${parts[1]}/${parts[2]}',
                                      style: const TextStyle(fontSize: 10));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
