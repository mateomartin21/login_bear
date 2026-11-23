import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'museum/gallery.dart';
import 'museum/night_art_card.dart';
import 'screens/login_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const local = bool.fromEnvironment('MUSEUM_AUTH_EMULATOR');
  var ready = false;
  try {
    await Firebase.initializeApp(
      options: local
          ? const FirebaseOptions(
              apiKey: 'local-demo-key',
              appId: '1:1234567890:web:0123456789abcdef',
              messagingSenderId: '1234567890',
              projectId: 'demo-museo-nocturno',
            )
          : kIsWeb
          ? const FirebaseOptions(
              apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
              appId: String.fromEnvironment('FIREBASE_APP_ID'),
              messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
              projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
            )
          : null,
    );
    if (local) {
      final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : '127.0.0.1';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    }
    ready = true;
  } on Exception catch (error) {
    debugPrint('No se pudo iniciar Firebase: ${error.runtimeType}');
  }
  runApp(NightMuseum(ready: ready));
}

class NightMuseum extends StatelessWidget {
  const NightMuseum({required this.ready, super.key});

  final bool ready;

  Widget _login(BuildContext context) => LoginScreens(destination: _gallery);

  Widget _gallery(BuildContext context) => Gallery(
    onExit: () async {
      final navigator = Navigator.of(context);
      try {
        await FirebaseAuth.instance.signOut();
        if (!navigator.mounted) return;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: _login),
          (_) => false,
        );
      } on FirebaseAuthException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cerrar la sesión. Intenta de nuevo.'),
          ),
        );
      }
    },
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Museo nocturno',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: nightLime,
        onPrimary: Colors.black,
        surface: Color(0xff171717),
        onSurface: Color(0xfff6f6f6),
        outline: Color(0xff85796a),
      ),
      scaffoldBackgroundColor: const Color(0xff090909),
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontFamily: 'Anton', fontSize: 38),
      ),
    ),
    home: !ready
        ? const Scaffold(
            body: Center(child: Text('No se pudo conectar con Firebase.')),
          )
        : Builder(
            builder: (context) => FirebaseAuth.instance.currentUser == null
                ? _login(context)
                : _gallery(context),
          ),
  );
}
