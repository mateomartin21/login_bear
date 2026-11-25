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
  final androidDemo =
      local && !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  FirebaseAuth? auth;
  try {
    final app = await Firebase.initializeApp(
      name: androidDemo ? 'nocturna-demo' : null,
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
    final museumAuth = FirebaseAuth.instanceFor(app: app);
    if (local) {
      await museumAuth.useAuthEmulator(
        androidDemo ? '10.0.2.2' : '127.0.0.1',
        9099,
      );
    }
    auth = museumAuth;
  } on FirebaseException catch (error) {
    debugPrint('No se pudo iniciar Firebase: ${error.code}');
  } on Exception catch (error) {
    debugPrint('No se pudo iniciar Firebase: ${error.runtimeType}');
  }
  runApp(NightMuseum(auth: auth));
}

class NightMuseum extends StatelessWidget {
  const NightMuseum({required this.auth, super.key});

  final FirebaseAuth? auth;

  Widget _login(BuildContext context) =>
      LoginScreens(destination: _gallery, auth: auth);

  Widget _gallery(BuildContext context) => Gallery(
    onExit: () async {
      final navigator = Navigator.of(context);
      try {
        await auth!.signOut();
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
    title: 'Nocturna · Galería de arte',
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff090909),
        titleTextStyle: TextStyle(
          fontFamily: 'Anton',
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xff202023),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xff151517),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.black
                : Colors.white70,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontFamily: 'Anton', fontSize: 38),
      ),
    ),
    home: auth == null
        ? const Scaffold(
            body: Center(child: Text('No se pudo conectar con Firebase.')),
          )
        : Builder(
            builder: (context) =>
                auth!.currentUser == null ? _login(context) : _gallery(context),
          ),
  );
}
