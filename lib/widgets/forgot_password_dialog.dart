import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> showForgotPasswordDialog(BuildContext context, String initialEmail) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});
  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  bool _sending = false;

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (email.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Ingresa tu correo')));
      return;
    }
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      navigator.pop();
      // Mensaje neutro: Firebase no revela si el correo existe (anti-enumeración).
      messenger.showSnackBar(const SnackBar(
        content: Text('Si el correo está registrado, recibirás un enlace para restablecer tu contraseña'),
      ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(
        content: Text(e.code == 'invalid-email'
            ? 'Correo inválido'
            : 'No se pudo enviar el correo, intenta de nuevo'),
      ));
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar contraseña'),
      content: TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(hintText: 'Tu correo'),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
