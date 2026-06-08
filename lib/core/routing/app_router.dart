/// Architectural role: Navigation configuration.
/// Defines all named routes using GoRouter.
/// Navigation is triggered by state changes in the notifier — never imperatively
/// from within build methods.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/ranking/presentation/views/screens/home_screen.dart';
import '../../features/ranking/presentation/views/screens/ranking_dashboard.dart';
import '../../features/ranking/presentation/views/screens/item_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/ranking',
      name: 'ranking',
      builder: (context, state) => const RankingDashboard(),
    ),
    GoRoute(
      path: '/detail/:itemId',
      name: 'detail',
      builder: (context, state) {
        final itemId = state.pathParameters['itemId'] ?? '';
        return ItemDetailScreen(itemId: itemId);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF09090B),
    body: Center(
      child: Text(
        'Route not found: ${state.uri}',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
);
