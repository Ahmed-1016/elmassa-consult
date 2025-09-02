import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ElMassaConsult/models/new_order-model.dart';

class SearchOrdersScreen extends StatefulWidget {
  const SearchOrdersScreen({super.key});

  @override
  State<SearchOrdersScreen> createState() => _SearchOrdersScreenState();
}

class _SearchOrdersScreenState extends State<SearchOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<NewOrderModel> searchResults = [];
  bool isSearching = false;

  Future<void> _searchOrders(String query) async {
    if (query.isEmpty) return;
    setState(() => isSearching = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('newOrders')
          .get();

      final results = snapshot.docs.map((doc) {
        return NewOrderModel.fromMap(doc.data() as Map<String, dynamic>);
        
      }).where((order) {
        final searchLower = query.toLowerCase();
        return order.orderNumber.toLowerCase().contains(searchLower) ||
            order.name.toLowerCase().contains(searchLower) ||
            order.unitType.toLowerCase().contains(searchLower) ||
            order.orderStatus.toLowerCase().contains(searchLower)||
            order.governorate.toLowerCase().contains(searchLower);
      }).toList();

      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (e) {
      setState(() => isSearching = false);
      Get.snackbar("خطأ", "فشل البحث عن الطلب",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("بحث عن طلب"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "أدخل رقم الطلب أو اسم العميل",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchOrders(_searchController.text.trim()),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (isSearching) const CircularProgressIndicator(),
            if (!isSearching && searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final order = searchResults[index];
                    return Card(
                      elevation: 3,
                      child: ListTile(
                        title: Text(order.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.orderNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(order.unitType),
                            Text(order.orderStatus,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Get.to(() => RejectedCommentsScreen(
                                govName: order.governorate,
                                orderNumber: order.orderNumber,
                              ));
                        },
                      ),
                    );
                  },
                ),
              ),
            if (!isSearching && searchResults.isEmpty)
              const Text("لا توجد نتائج",
                  style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class RejectedCommentsScreen extends StatelessWidget {
  final String govName;
  final String orderNumber;

  const RejectedCommentsScreen({
    super.key,
    required this.govName,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("التعليقات"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('elmassaConsult')
            .doc(govName)
            .collection('newOrders')
            .doc(orderNumber)
            .collection('rejected')
            .orderBy('createdOn', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("لا توجد تعليقات", style: TextStyle(color: Colors.grey)));
          }

          final comments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final data = comments[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['comments'] ?? 'بدون تعليق',style: TextStyle(color: Colors.green),),
                  trailing: Text(data['username'] ?? 'غير محدد',style: TextStyle(color: Colors.red),),
                  subtitle: Text(
                      " ${data['createdOn'] != null ? (data['createdOn'] as Timestamp).toDate().toString() : 'غير محدد'}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
