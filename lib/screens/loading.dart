import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background.withAlpha(150),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
