import 'package:flutter/material.dart';

import '../features/home/home_page.dart';

class WakeQuestApp extends StatelessWidget {
  const WakeQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeQuest',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),

      home: const HomePage(),
    );
  }
}
