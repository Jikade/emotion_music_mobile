import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'router.dart';

class EmotionMusicMobileApp extends StatelessWidget {
  const EmotionMusicMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Emotion Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
