import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:login_bear/screens/login_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lee la config de android/app/google-services.json
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreens(),
    );
  }
}
