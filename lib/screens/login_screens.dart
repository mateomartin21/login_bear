import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; 

class LoginScreens extends StatefulWidget {
  const new({super.key});

  
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