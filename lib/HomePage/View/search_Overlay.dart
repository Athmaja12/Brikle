// import 'package:brikle/HomePage/View/search_Suggestion.dart';
// import 'package:flutter/material.dart';

// class SearchOverlay extends StatelessWidget {
//   final Widget child;
//   final bool isVisible;

//   const SearchOverlay({
//     super.key,
//     required this.child,
//     required this.isVisible,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         child,
//         if (isVisible)
//           Positioned.fill(
//             child: GestureDetector(
//               onTap: () {
//                 // Dismiss keyboard but keep search active
//                 FocusScope.of(context).unfocus();
//               },
//               child: Container(
//                 color: Colors.black.withOpacity(0.3),
//                 child: const Center(
//                   child: _SearchOverlayContent(),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// class _SearchOverlayContent extends StatelessWidget {
//   const _SearchOverlayContent();

//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final topPadding = mediaQuery.padding.top;
    
//     return Container(
//       margin: EdgeInsets.only(top: topPadding + 80),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(16),
//         ),
//       ),
//       child: const Column(
//         children: [
//           // Drag handle
//           Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Center(
//               child: SizedBox(
//                 width: 36,
//                 height: 4,
//                 child: DecoratedBox(
//                   decoration: BoxDecoration(
//                     color: Colors.grey,
//                     borderRadius: BorderRadius.all(Radius.circular(2)),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: SearchSuggestions(),
//           ),
//         ],
//       ),
//     );
//   }
// }