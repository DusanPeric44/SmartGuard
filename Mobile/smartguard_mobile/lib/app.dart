import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/deep_link_handler.dart';
import 'core/push/push_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';

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
      final router = ref.read(goRouterProvider);
      _deepLinkHandler.start(router);
      ref.read(pushNotificationsHandlerProvider).start(ref, router);
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
      title: AppStrings.appTitle,
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
