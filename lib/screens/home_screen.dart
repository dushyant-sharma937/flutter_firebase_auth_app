import 'package:flutter/material.dart';
import 'package:flutter_firebase_auth_app/provider/sign_in_provider.dart';
import 'package:flutter_firebase_auth_app/screens/login_screen.dart';
import 'package:flutter_firebase_auth_app/utils/next_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future getData() async {
    final sp = context.read<SignInProvider>();
    sp.getDataFromSharedPreferences();
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // here I am using watch instead of read, because watch also updates the
    // changes that happens to the data.
    final sp = context.watch<SignInProvider>();
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: NetworkImage("${sp.imageUrl}"),
            radius: 80,
          ),
          const SizedBox(height: 20),
          Text(
            "Welcome ${sp.name}",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${sp.email}",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${sp.uid}",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Provider:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                "${sp.provider}",
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: MaterialButton(
              onPressed: () {
                sp.userSignOut();
                nextScreenReplace(context, const LoginScreen());
              },
              minWidth: MediaQuery.of(context).size.width * 0.8,
              height: 45,
              shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              color: Colors.blue,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Sign out',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.exit_to_app,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
