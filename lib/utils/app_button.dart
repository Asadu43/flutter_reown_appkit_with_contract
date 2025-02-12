// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import 'AppColors.dart';
//
// class AppButton extends StatelessWidget {
//   final String text;
//   final VoidCallback? onPressed;
//   final String? icon;
//   const AppButton({Key? key, required this.text, this.onPressed, this.icon}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: SizedBox(
//         width: MediaQuery.of(context).size.width * 0.7,
//         height: MediaQuery.of(context).size.height * 0.050,
//         child: ElevatedButton(
//           onPressed: onPressed,
//           style: ButtonStyle(
//             backgroundColor: MaterialStateProperty.all<Color>(AppColors.buttonColor),
//             shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//               RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20.0), // Adjust the radius as needed
//               ),
//             ),
//           ),
//           child: Text(
//             text,
//             style: GoogleFonts.barlow(
//               fontSize: 16,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
