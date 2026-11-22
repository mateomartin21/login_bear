import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_bear/screens/products_screen.dart';
import 'package:login_bear/screens/sign_up_screen.dart';
import 'package:login_bear/widgets/forgot_password_dialog.dart';
import 'package:rive/rive.dart';

class LoginScreens extends StatefulWidget {
  const LoginScreens({super.key});

  @override
  State<LoginScreens> createState() => _LoginScreensState();
}

class _LoginScreensState extends State<LoginScreens> {
  bool _isObscure = true;
  bool _loading = false;

  //  1.1 Maquina estados / Cerebro de la animación
  StateMachineController? _controller;
  // StateMachineInput
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  Timer? _typingDebounce;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // OWASP A07: un único mensaje global, sin decir qué campo falló.
  void _fail(String message) {
    if (!mounted) return;
    setState(() => _loading = false);
    _trigFail?.fire();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onLogin() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // Solo se valida que no estén vacíos; la complejidad se exige únicamente al registrar.
    if (email.isEmpty || pass.isEmpty) {
      _fail('Ingresa tu correo y contraseña');
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login falló: ${e.code}');
      _fail(e.code == 'network-request-failed'
          ? 'Sin conexión a internet'
          : 'Credenciales inválidas');
      return;
    }

    _trigSuccess?.fire();
    // Dejar que la animación de éxito se vea antes de navegar.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProductsScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocus.addListener(() {
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
        body: SingleChildScrollView(
      child: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(
              width: screenSize.width,
              height: 200,
              child: RiveAnimation.asset('assets/login-bear-animation.riv',
                  stateMachines: ['Login Machine'],
                  //1.2 Vincular la animación
                  onInit: (artboard) {
                _controller = StateMachineController.fromArtboard(
                  artboard,
                  'Login Machine',
                );
                if (_controller == null) return;
                artboard.addController(_controller!);
                _isChecking = _controller!.findSMI('isChecking');
                _isHandsUp = _controller!.findSMI('isHandsUp');
                _trigSuccess = _controller!.findSMI('trigSuccess');
                _trigFail = _controller!.findSMI('trigFail');
                _numLook = _controller!.findSMI('numLook');
              }),
            ),
            const SizedBox(height: 10),
            //Email
            TextField(
              controller: emailCtrl,
              focusNode: _emailFocus,
              onChanged: (value) {
                if (_isChecking == null) return;
                _isChecking!.change(true);
                final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                _numLook?.value = look;

                _typingDebounce?.cancel();
                _typingDebounce = Timer(const Duration(seconds: 3), () {
                  if (!mounted) return;
                  _isChecking?.change(false);
                });
              },
              decoration: InputDecoration(
                  hintText: "E-mail",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                      //Para redondear bordes
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 10),
            //Contraseña
            TextField(
              controller: passCtrl,
              focusNode: _passwordFocus,
              onChanged: (value) {
                if (_isHandsUp == null) return;
                _isHandsUp!.change(true);
              },
              obscureText: _isObscure,
              decoration: InputDecoration(
                  hintText: "Contraseña",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                      onPressed: () {
                        //Refrescar el icono
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: Icon(
                          //If ternario
                          _isObscure ? Icons.visibility : Icons.visibility_off)),
                  border: OutlineInputBorder(
                      //Para redondear bordes
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => showForgotPasswordDialog(context, emailCtrl.text.trim()),
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
            const SizedBox(height: 10),
            MaterialButton(
              minWidth: screenSize.width,
              height: 50,
              color: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onPressed: _loading ? null : _onLogin,
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: screenSize.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                      onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          ),
                      child: const Text("Sign up",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          )))
                ],
              ),
            )
          ],
        ),
      )),
    ));
  }

  @override
  void dispose() {
    // Liberar memoria en los focusNode
    _emailFocus.dispose();
    _passwordFocus.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}
