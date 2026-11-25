import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_bear/screens/products_screen.dart';
import 'package:login_bear/screens/sign_up_screen.dart';
import 'package:login_bear/widgets/forgot_password_dialog.dart';
import 'package:rive/rive.dart';

class LoginScreens extends StatefulWidget {
  const LoginScreens({super.key, this.destination, this.auth});
  final FirebaseAuth? auth;

  final WidgetBuilder? destination;

  @override
  State<LoginScreens> createState() => _LoginScreensState();
}

class _LoginScreensState extends State<LoginScreens> {
  bool _isObscure = true;
  bool _loading = false;

  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;
  SMIBool? _isSubmitting;
  Completer<void>? _welcome;

  Timer? _typingDebounce;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool get _museum => widget.destination != null;

  void _bindAnimation(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'Login Machine',
    );
    if (controller == null) return;
    artboard.addController(controller);
    _isChecking = controller.getBoolInput('isChecking');
    _isHandsUp = controller.getBoolInput('isHandsUp');
    _trigSuccess = controller.getTriggerInput('trigSuccess');
    _trigFail = controller.getTriggerInput('trigFail');
    _numLook = controller.getNumberInput('numLook');
    _isSubmitting = controller.getBoolInput('isSubmitting');
    _isChecking?.change(_emailFocus.hasFocus);
    _isHandsUp?.change(_passwordFocus.hasFocus);
    _isSubmitting?.change(_loading);
    controller.addEventListener((event) {
      final welcome = _welcome;
      if (event.name == 'loginSuccessComplete' &&
          welcome != null &&
          !welcome.isCompleted) {
        welcome.complete();
      }
    });
  }

  // OWASP A07: un único mensaje global, sin decir qué campo falló.
  void _fail(String message) {
    if (!mounted) return;
    setState(() => _loading = false);
    _isSubmitting?.change(false);
    _trigFail?.fire();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onLogin() async {
    if (_loading) return;
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    if (email.isNotEmpty && pass.isNotEmpty) passCtrl.clear();
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
    _isSubmitting?.change(true);
    try {
      await (widget.auth ?? FirebaseAuth.instance).signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login falló: ${e.code}');
      _fail(
        e.code == 'network-request-failed'
            ? 'Sin conexión a internet'
            : 'Credenciales inválidas',
      );
      return;
    }

    if (!mounted) return;
    emailCtrl.clear();
    _isSubmitting?.change(false);
    if (!MediaQuery.disableAnimationsOf(context)) {
      final welcome = _welcome = Completer<void>();
      _trigSuccess?.fire();
      // A missing asset or a paused tab must never block an authenticated session.
      await welcome.future.timeout(
        Duration(milliseconds: _museum ? 1150 : 2000),
        onTimeout: () {},
      );
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: widget.destination ?? (_) => const ProductsScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      _isChecking?.change(_emailFocus.hasFocus);
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
    final museum = _museum;
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (museum) ...[
                      Text.rich(
                        const TextSpan(
                          text: 'NOCTURNA ',
                          children: [
                            TextSpan(
                              text: '//',
                              style: TextStyle(color: Color(0xffff665e)),
                            ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Entra al taller y explora la colección.'),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: screenSize.width,
                      height: museum ? 218 : 200,
                      child: RiveAnimation.asset(
                        museum
                            ? 'assets/nocturna-painter.riv'
                            : 'assets/login-bear-animation.riv',
                        key: ValueKey(reduceMotion),
                        useArtboardSize: false,
                        onInit: (artboard) {
                          if (!reduceMotion) _bindAnimation(artboard);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    //Email
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      focusNode: _emailFocus,
                      onChanged: (value) {
                        if (_isChecking == null) return;
                        _isChecking!.change(true);
                        final look = (value.length / 80.0 * 100.0).clamp(
                          0.0,
                          100.0,
                        );
                        _numLook?.value = look;

                        _typingDebounce?.cancel();
                        _typingDebounce = Timer(const Duration(seconds: 3), () {
                          if (!mounted) return;
                          _isChecking?.change(false);
                        });
                      },
                      decoration: InputDecoration(
                        labelText: museum ? 'Correo electrónico' : 'E-mail',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          //Para redondear bordes
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    //Contraseña
                    TextField(
                      controller: passCtrl,
                      focusNode: _passwordFocus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_loading) _onLogin();
                      },
                      onChanged: (value) {
                        if (_isHandsUp == null) return;
                        _isHandsUp!.change(true);
                      },
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
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
                            _isObscure
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                        border: OutlineInputBorder(
                          //Para redondear bordes
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => showForgotPasswordDialog(
                          context,
                          emailCtrl.text.trim(),
                          auth: widget.auth,
                        ),
                        child: Text(
                          museum
                              ? '¿Olvidaste tu contraseña?'
                              : 'Forgot password?',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    MaterialButton(
                      minWidth: screenSize.width,
                      height: 50,
                      color: museum ? colors.primary : Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onPressed: _loading ? null : _onLogin,
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              museum ? 'Entrar al museo' : 'Login',
                              style: TextStyle(
                                color: museum ? colors.onPrimary : Colors.white,
                                fontSize: 18,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: screenSize.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            museum
                                ? '¿Primera visita?'
                                : "Don't have an account?",
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SignUpScreen(auth: widget.auth),
                                    ),
                                  ),
                            child: Text(
                              museum ? 'Crear cuenta' : 'Sign up',
                              style: TextStyle(
                                color: museum ? colors.primary : Colors.black,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
