import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_bear/screens/products_screen.dart';
import 'package:rive/rive.dart';
import 'dart:async';

class LoginScreens extends StatefulWidget {
  const LoginScreens({super.key});

  
  @override
  State<LoginScreens> createState() => _LoginScreensState();
}

class _LoginScreensState extends State<LoginScreens> {
  bool _isObscure= true; 

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

  String? emailError;
  String? passError;

   // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  Future<void> _onLogin() async {
    final email = emailCtrl.text.trim(); 
    final pass = passCtrl.text; 
    final emailTypedError = isValidEmail(email)? null : 'Email inválido'; 
    final passTypedError = isValidPassword(pass)? null : 'Contraseña inválida'; 

    setState(() {
      emailError = emailTypedError; 
      passError = passTypedError; 
    });

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false); 
    _isHandsUp?.change(false); 
    _numLook?.value = 50.0;

    if (emailTypedError != null || passTypedError != null) {
      _trigFail?.fire();
      return;
    }

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      // Credenciales que cumplen el regex pero Firebase rechaza: sin error por campo.
      _trigFail?.fire();
      debugPrint('Firebase login falló: ${e.code}');
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
      
      if (_emailFocus.hasFocus){
        if (_isHandsUp != null){
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
                  onInit: (artboard){
                    _controller = StateMachineController.fromArtboard(artboard, 'Login Machine', );
                    if (_controller == null) return; 
                    artboard.addController(_controller!);
                    _isChecking = _controller!.findSMI('isChecking'); 
                    _isHandsUp = _controller!.findSMI('isHandsUp');
                    _trigSuccess = _controller!.findSMI('trigSuccess');
                    _trigFail = _controller!.findSMI('trigFail'); 
                    _numLook = _controller!.findSMI('numLook'); 
                  }
                  ),
                ),
                SizedBox(height: 10,),
                //Email
                TextField(
                  controller: emailCtrl,
                  focusNode: _emailFocus,
                  onChanged:(value) {
                    if (_isHandsUp != null){
                    //  _isHandsUp!.change(false);
                    }

                    if (_isChecking == null) return;
                    _isChecking!.change(true);
                    final look = (value.length / 80.0*100.0).clamp(0.0, 100.0);
                    _numLook?.value = look;

                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(const Duration(seconds: 3), (){
                      if (!mounted) return; 
                      _isChecking?.change(false); 
                    });
                  },
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: "E-mail", 
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      //Para redondear bordes
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
                const SizedBox(height: 10),
                //Contraseña
                TextField(
                    controller : passCtrl, 
                    focusNode: _passwordFocus,
                    onChanged:(value) {
                    if (_isChecking != null){
                      //_isChecking!.change(false);
                    }

                    if (_isHandsUp == null) return;
                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    errorText: passError,
                    hintText: "Contraseña", 
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                    onPressed: (){
                      //Refrescar el icono
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    }, 
                    icon: Icon(
                      //If ternario
                      _isObscure ? Icons.visibility : Icons.visibility_off
                    )),
                    border: OutlineInputBorder(
                      //Para redondear bordes
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
                const SizedBox(height:10),
                SizedBox(
                  width : screenSize.width,
                  child : const Text("Forgot password?",
                  textAlign: TextAlign.right,
                  style: TextStyle(decoration: TextDecoration.underline),
                  ),

                ),
                const SizedBox(height:10),
                MaterialButton(
                  minWidth: screenSize.width,
                  height :50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12),

                  ),

                  onPressed: _onLogin,
                  child: Text(
                    "Login",
                    style: TextStyle(color:  Colors.white, fontSize:18),

                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(onPressed: (){}, child: Text("Register",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      )
                      )
                      )
                    ],
                  ),
                )
              ],
            ),
          )),
      )
    );
  }
  @override
  void dispose() {
    // Liberar memoria en los focusNode 
    _emailFocus.dispose();
    _passwordFocus.dispose(); 
    _typingDebounce?.cancel();
    super.dispose();
  }
}