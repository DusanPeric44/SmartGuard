import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/deep_link_handler.dart';
import 'core/theme/app_theme.dart';

class SmartGuardApp extends ConsumerStatefulWidget {
  const SmartGuardApp({super.key});

  @override
  ConsumerState<SmartGuardApp> createState() => _SmartGuardAppState();
}

class _SmartGuardAppState extends ConsumerState<SmartGuardApp> {
  final DeepLinkHandler _deepLinkHandler = DeepLinkHandler();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkHandler.start(ref.read(goRouterProvider));
    });
  }

  @override
  void dispose() {
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'SmartGuard',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
