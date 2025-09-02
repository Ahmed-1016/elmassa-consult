// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ElMassaConsult/models/comments_model.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/services.dart'; // For Clipboard

class RejectedChatScreen extends StatefulWidget {
  final String name;
  final String orderNumber;
  final String userName;
  final String userCode;
  final String govName;

  const RejectedChatScreen({
    super.key,
    required this.name,
    required this.orderNumber,
    required this.userName,
    required this.userCode,
    required this.govName,
  });

  @override
  _RejectedChatScreenState createState() => _RejectedChatScreenState();
}

class _RejectedChatScreenState extends State<RejectedChatScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FocusNode _commentFocusNode = FocusNode(); // For handling Enter key

  // Helper to build chat bubbles
  Widget _buildChatBubble(CommentsModel comment) {
    bool isCurrentUser = comment.usercode == widget.userCode;
    Alignment alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    Color bubbleColor =
        isCurrentUser ? Theme.of(context).primaryColorLight : Colors.grey[300]!;
    Color textColor = isCurrentUser
        ? Colors.black87
        : Colors.black87; // Or Colors.white for primaryColor

    return GestureDetector(
      onLongPress: () {
        // "Copy Text"

        Clipboard.setData(ClipboardData(text: comment.comments));
        // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم النسخ'),
            duration: Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        alignment: alignment,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser)
                Text(
                  comment.username,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                      color: textColor.withOpacity(0.8)),
                ),
              Text(
                comment.comments,
                style: TextStyle(fontSize: 16.0, color: textColor),
              ),
              const SizedBox(height: 4.0),
              Text(
                DateFormat('yyyy-MM-dd HH:mm')
                    .format(comment.createdOn), // HH:mm for time
                style: TextStyle(
                    fontSize: 10.0, color: textColor.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        centerTitle: true,
        title: Text("المحادثة"
            ), // "Rejection Reason Chat"
      ),
      body: Column(
        children: [
          Text(widget.name,
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('elmassaConsult')
                  .doc(widget.govName)
                  .collection('newOrders')
                  .doc(widget.orderNumber)
                  .collection('rejected')
                  .orderBy('createdOn',
                      descending:
                          false) // Show oldest first, then reverse in ListView
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          'حدث خطأ ما: ${snapshot.error}')); // "Something went wrong"
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final commentsDocs = snapshot.data?.docs ?? [];
                if (commentsDocs.isEmpty) {
                  return Center(child: Text('لا توجد تعليقات بعد'));
                }

                return ListView.builder(
                  reverse: true, // To keep chat at the bottom and scroll up
                  padding: const EdgeInsets.all(8.0),
                  itemCount: commentsDocs.length,
                  itemBuilder: (context, index) {
                    // Correctly access reversed list
                    final commentData =
                        commentsDocs[commentsDocs.length - 1 - index].data()
                            as Map<String, dynamic>;
                    final comment = CommentsModel.fromMap(commentData);
                    return _buildChatBubble(comment);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    textInputAction:
                        TextInputAction.send, // Show send button on keyboard
                    onSubmitted: (value) =>
                        _sendComment(), // Send on enter/send button
                    decoration: InputDecoration(
                      hintText:
                          'اكتب تعليقك هنا...', // "Write your comment here..."
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      final comment = CommentsModel(
        orderNumber: widget.orderNumber,
        username: widget.userName,
        usercode:
            widget.userCode, // Corrected parameter name from previous step
        createdOn: DateTime.now(),
        comments: commentText,
      );

      try {
        await _firestore
            .collection('elmassaConsult')
            .doc(widget.govName)
            .collection('newOrders')
            .doc(widget.orderNumber)
            .collection('rejected')
            .add(comment.toMap());
        _commentController.clear();
        _commentFocusNode.requestFocus(); // Keep focus on text field
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إرسال التعليق: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }
}
