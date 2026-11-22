import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_bear/utils/validators.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  // En registro sí se permiten mensajes específicos (OWASP: solo el login es genérico).
  String _messageFor(String code) => switch (code) {
        'email-already-in-use' => 'Este correo ya está registrado',
        'weak-password' => 'La contraseña es demasiado débil',
        'invalid-email' => 'Correo inválido',
        'network-request-failed' => 'Sin conexión a internet',
        _ => 'No se pudo crear la cuenta, intenta de nuevo',
      };

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // createUser deja la sesión abierta; se cierra para que entre desde el Login.
      await FirebaseAuth.instance.signOut();
      messenger.showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Ahora inicia sesión')),
      );
      navigator.pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text(_messageFor(e.code))));
    }
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Correo institucional', Icons.email),
                validator: (v) => isInstitutionalEmail((v ?? '').trim())
                    ? null
                    : 'Usa tu correo @tecdesoftware.edu.mx',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: _decoration(
                  'Contraseña',
                  Icons.lock,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) => isStrongPassword(v ?? '')
                    ? null
                    : 'Mínimo 8 caracteres, con mayúscula, minúscula, número y símbolo',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: _decoration('Confirmar contraseña', Icons.lock_outline),
                validator: (v) =>
                    v == _passCtrl.text ? null : 'Las contraseñas no coinciden',
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reglas de la contraseña:\n'
                  '• Mínimo 8 caracteres\n'
                  '• Una mayúscula y una minúscula\n'
                  '• Un número y un símbolo',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
              MaterialButton(
                minWidth: double.infinity,
                height: 50,
                color: Colors.pinkAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onPressed: _loading ? null : _signUp,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Sign up', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
