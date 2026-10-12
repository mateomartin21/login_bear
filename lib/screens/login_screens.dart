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
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: screenSize.width,
                height: 200,
                child: RiveAnimation.asset('assets/login-bear-animation.riv')),
            ],
          ),
        ))
    );
  }
}