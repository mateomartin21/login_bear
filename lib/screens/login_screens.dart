import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreens extends StatefulWidget {
  const new({super.key});

  @override
  State<LoginScreens> createState() => _LoginScreensState();
}

class _LoginScreensState extends State<LoginScreens> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RiveAnimation.asset('assets/login-bear-animation.riv')
    );
  }
}