import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/auth/ui/login_page.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(body: Center(child: Text("Home Page Placeholder"))),
    ),
  ],
);
