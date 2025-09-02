import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class UserWithPerformance {
  final String id;
  final String username;
  final String usercode;
  final String source;
  final List<QueryDocumentSnapshot> performanceDocs;

  UserWithPerformance({
    required this.id,
    required this.username,
    required this.usercode,
    required this.source,
    required this.performanceDocs,
  });
}

class PerformanceDashboard extends StatefulWidget {
  const PerformanceDashboard({super.key});

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard> {
  List<UserWithPerformance> allUsers = [];
  bool isLoading = true;
  String selectedSource = 'مكتب'; // القيمة الافتراضية

  @override
  void initState() {
    super.initState();
    loadAllUserPerformances();
  }

  Future<void> loadAllUserPerformances() async {
    try {
      final officeUsers = await FirebaseFirestore.instance.collection('PrOfficeTeamWork').get();
      final siteUsers = await FirebaseFirestore.instance.collection('PrSiteTeamWork').get();

      List<UserWithPerformance> loadedUsers = [];

      Future<void> loadUsersFromCollection(QuerySnapshot usersSnapshot, String source) async {
        for (var userDoc in usersSnapshot.docs) {
          final perRateSnapshot = await userDoc.reference.collection('PerRate').get();

          if (perRateSnapshot.docs.isNotEmpty) {
            final firstDocData = perRateSnapshot.docs.first.data() as Map<String, dynamic>;
            final username = firstDocData['username'] ?? userDoc.id;
            final usercode = firstDocData['usercode'] ?? '';

            loadedUsers.add(UserWithPerformance(
              id: userDoc.id,
              username: username,
              usercode: usercode,
              source: source,
              performanceDocs: perRateSnapshot.docs,
            ));
          }
        }
      }

      await loadUsersFromCollection(officeUsers, 'مكتب');
      await loadUsersFromCollection(siteUsers, 'موقع');

      setState(() {
        allUsers = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      print("❌ خطأ: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = allUsers.where((u) => u.source == selectedSource).toList();

    return Scaffold(
appBar: AppBar(
  title: Row(
    children: [
      const Text('لوحة الأداء'),
      const Spacer(), // يدفع DropdownButton إلى أقصى اليسار
      Padding(
        padding: const EdgeInsets.only(left: 50),
        child: DropdownButton<String>(
          
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          value: selectedSource,
          items: const [
            DropdownMenuItem(value: 'مكتب', child: Text('المكتب الفني',style: TextStyle(fontSize: 16),)),
            DropdownMenuItem(value: 'موقع', child: Text('الموقع',style: TextStyle(fontSize: 16),)),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedSource = value;
              });
            }
          },
          underline: const SizedBox(),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    ],
  ),
),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredUsers.isEmpty
              ? const Center(child: Text('لا يوجد بيانات للمصدر المحدد'))
              : ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return UserPerformanceChart(user: user);
                  },
                ),
    );
  }
}

class UserPerformanceChart extends StatelessWidget {
  final UserWithPerformance user;

  const UserPerformanceChart({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final docs = user.performanceDocs;
    final stageCounts = <String, int>{};
    final dateCounts = <String, int>{};

    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final stage = data['orderStatus'] ?? 'غير معروف';
      final createdOn = (data['createdOn'] as Timestamp).toDate();
      final dayKey = DateFormat('yyyy-MM-dd').format(createdOn);

      stageCounts[stage] = (stageCounts[stage] ?? 0) + 1;
      dateCounts[dayKey] = (dateCounts[dayKey] ?? 0) + 1;

      if (createdOn.isAfter(today)) todayCount++;
      if (createdOn.isAfter(weekAgo)) weekCount++;
      if (createdOn.isAfter(monthAgo)) monthCount++;
    }

    final last30Days = List.generate(30, (i) {
      final day = today.subtract(Duration(days: 29 - i));
      return DateFormat('yyyy-MM-dd').format(day);
    });

    final sortedDateEntries = last30Days.map((dayKey) {
      return MapEntry(dayKey, dateCounts[dayKey] ?? 0);
    }).toList();

    return Card(
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user.username} (${user.source})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('إجمالي الطلبات: ${docs.length}'),
            const SizedBox(height: 8),
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    _buildCountTile('اليوم', todayCount),
    _buildCountTile('الأسبوع', weekCount),
    _buildCountTile('الشهر', monthCount),
  ],
),
const SizedBox(height: 20),
const Divider(thickness: 1.2),
const SizedBox(height: 25),
            const Text('مخطط المراحل'),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: stageCounts.entries.map((e) {
                    final color = _colorForStage(e.key);
                    return BarChartGroupData(
                      x: stageCounts.keys.toList().indexOf(e.key),
                      barRods: [
                        BarChartRodData(toY: e.value.toDouble(), color: color, width: 18),
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
                          if (index < stageCounts.length) {
                            return Text(stageCounts.keys.elementAt(index), style: const TextStyle(fontSize: 10));
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
            const SizedBox(height: 8),
            const Text('المخطط الزمني'),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: List.generate(sortedDateEntries.length, (index) {
                        final entry = sortedDateEntries[index];
                        return FlSpot(index.toDouble(), entry.value.toDouble());
                      }),
                      barWidth: 2,
                      color: Colors.blue,
                      dotData: FlDotData(show: true),
                    )
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < sortedDateEntries.length) {
                            final key = sortedDateEntries[index].key;
                            final parts = key.split('-');
                            return Text('${parts[1]}/${parts[2]}', style: const TextStyle(fontSize: 10));
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

  Widget _buildCountTile(String label, int count) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
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
}
