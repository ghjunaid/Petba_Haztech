// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:petba_new/chat/Model/ChatModel.dart';
// import 'package:petba_new/chat/Model/Messagemodel.dart';
// import 'package:petba_new/chat/screens/Individualpage.dart';
//
//
// class Customcard extends StatelessWidget {
//   final ChatModel chatModel;
//   final ChatModel sourchat;
//   const Customcard({Key? key,required this.chatModel, required this.sourchat}) : super(key: key);
//
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//           context, MaterialPageRoute(builder: (context)=>Individualpage(chatModel: chatModel,sourchat: sourchat,))
//         );
//       },
//       child: Column(
//         children: [
//           ListTile(
//             leading: CircleAvatar(
//               radius: 25,
//               child: SvgPicture.asset(chatModel.isGroup? "assets/groups.svg" : "assets/person.svg",
//                 height: 37,
//                 width: 37,
//               ),
//             ),
//             title: Text(chatModel.name,
//               style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
//               ),
//             ),
//             subtitle: Row(
//               children: [
//                 Icon(Icons.done_all),
//                 SizedBox(
//                   width: 3,
//                 ),
//                 Text(chatModel.currentMessage,
//                   style: TextStyle(
//                     fontSize: 13,
//                   ),
//                 )
//               ],
//             ),
//             trailing: Text(chatModel.time),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Divider(
//               thickness: 1,
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
//
