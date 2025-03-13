import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:peyazma_windows/pages/login_page.dart' deferred as login;
// import 'package:peyazma_windows/pages/dashboard.dart' deferred as dash;
// import 'package:peyazma_windows/pages/splash_screen.dart' deferred as splash;

// class AppRouter {
//   static final GoRouter _router = GoRouter(
//     initialLocation: '/splash',
//     routes: [
// GoRoute(
//   path: '/',
//   name: 'home',
//   builder: (context, state) => const HomePage(),
// ),
//       GoRoute(
//         path: '/login',
//         name: 'login',
//         builder: (context, state) {
//           return FutureBuilder(
//             future: login.loadLibrary(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.done) {
//                 return login.LoginPage();
//               } else {
//                 return const Center(child: CircularProgressIndicator());
//               }
//             },
//           );
//         },
//       ),
//       GoRoute(
//         path: '/dash',
//         name: 'dashboard',
//         builder: (context, state) {
//           return FutureBuilder(
//             future: dash.loadLibrary(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.done) {
//                 return dash.Dashboard();
//               } else {
//                 return const Center(child: CircularProgressIndicator());
//               }
//             },
//           );
//         },
//       ),
//       GoRoute(
//         path: '/splash',
//         name: 'splash_screen',
//         builder: (context, state) {
//           return FutureBuilder(
//             future: splash.loadLibrary(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.done) {
//                 return splash.SplashScreen();
//               } else {
//                 return const Center(child: CircularProgressIndicator());
//               }
//             },
//           );
//         },
//       ),
//     ],
//   );
//
//   GoRouter get router => _router;
// }
