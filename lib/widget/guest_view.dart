// import 'package:flutter/material.dart';
// import '../theme/app_theme.dart';
// import '../services/firebase_auth_service.dart';
// import '../screens/login_screen.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:characters/characters.dart';

//   Widget _buildGuestView() {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(32),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Cooking illustration
//                 Container(
//                   width: 160,
//                   height: 160,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppTheme.primaryOrange.withOpacity(0.2),
//                         blurRadius: 30,
//                         offset: const Offset(0, 10),
//                       ),
//                     ],
//                   ),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       Icon(
//                         Icons.restaurant_menu_rounded,
//                         size: 70,
//                         color: AppTheme.primaryOrange.withOpacity(0.8),
//                       ),
//                       Positioned(
//                         top: 30,
//                         right: 35,
//                         child: Icon(
//                           Icons.favorite,
//                           size: 24,
//                           color: Colors.red.withOpacity(0.6),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 const Text(
//                   'Chào mừng bạn!',
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   'Đăng nhập để khám phá hàng ngàn công thức nấu ăn ngon, lưu món yêu thích và chia sẻ niềm đam mê ẩm thực của bạn.',
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: Colors.grey[600],
//                     height: 1.6,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 40),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.of(context).pushAndRemoveUntil(
//                         MaterialPageRoute(builder: (_) => const LoginScreen()),
//                         (route) => false,
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.primaryOrange,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 0,
//                       shadowColor: AppTheme.primaryOrange.withOpacity(0.3),
//                     ),
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.login_rounded, size: 22),
//                         SizedBox(width: 8),
//                         Text(
//                           'Đăng nhập ngay',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextButton(
//                   onPressed: () {
//                     // Navigate to register
//                   },
//                   child: Text(
//                     'Chưa có tài khoản? Đăng ký',
//                     style: TextStyle(
//                       color: Colors.grey[700],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }