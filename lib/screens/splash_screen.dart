import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_firebase_auth_app/provider/sign_in_provider.dart';
import 'package:flutter_firebase_auth_app/screens/home_screen.dart';
import 'package:flutter_firebase_auth_app/screens/login_screen.dart';
import 'package:provider/provider.dart';

import '../utils/next_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    final sp = context.read<SignInProvider>();
    super.initState();
    Timer(const Duration(seconds: 2), () {
      sp.isSignedIn == false
          ? nextScreen(context, const LoginScreen())
          : nextScreen(context, const HomeScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Image(
            image: AssetImage(
              'assets/images/authentication.png',
            ),
            height: 120,
            width: 120,
          ),
        ),
      ),
    );
  }
}
