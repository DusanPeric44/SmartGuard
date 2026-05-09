import 'package:flutter/material.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}

