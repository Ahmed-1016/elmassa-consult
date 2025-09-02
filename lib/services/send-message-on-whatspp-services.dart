// // ignore_for_file: deprecated_member_use, file_names


// import 'package:url_launcher/url_launcher.dart';

// Future<void> sendMessageOnWhatsApp({
//   required ProductModel productModel,
// }) async {
//   final number = "+201158551439";
//   final message =
//       "السلام عليكم \n اريد الاستفسار عن \n ${productModel.productName} \n ${productModel.productId}";
//   final url = 'http://wa.me/$number?text=${Uri.encodeComponent(message)}';
//   if (await canLaunch(url)) {
//     await launch(url);
//   } else {
//     throw 'could not launch $url';
//   }
// }
