import 'package:awesome_icons/awesome_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_auth_app/provider/sign_in_provider.dart';
import 'package:flutter_firebase_auth_app/screens/home_screen.dart';
import 'package:flutter_firebase_auth_app/utils/next_screen.dart';
import 'package:flutter_firebase_auth_app/utils/snackbar.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:provider/provider.dart';

import '../provider/internet_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey _scaffoldKey = GlobalKey<ScaffoldState>();
  final RoundedLoadingButtonController googleController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController facebookController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController twitterController =
      RoundedLoadingButtonController();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    Image(
                      image: AssetImage('assets/images/authentication.png'),
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Welcome to Flutter Authentication Application',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RoundedButton(
                    size: size,
                    googleController: googleController,
                    icon: FontAwesomeIcons.google,
                    text: 'Google',
                    color: const Color(0xffE84234),
                    function: handleGoogleSignIn,
                  ),
                  const SizedBox(height: 15),
                  RoundedButton(
                    size: size,
                    googleController: facebookController,
                    icon: FontAwesomeIcons.facebook,
                    text: 'Facebook',
                    color: const Color(0xff4866AB),
                    function: () {},
                  ),
                  const SizedBox(height: 15),
                  RoundedButton(
                    size: size,
                    googleController: twitterController,
                    icon: FontAwesomeIcons.twitter,
                    text: 'Twitter',
                    color: const Color(0xff1CA0F2),
                    function: () {},
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future handleGoogleSignIn() async {
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();

    if (ip.hasInternet == false) {
      openSnackBar(context, "Check your Internet connection", Colors.red);
      googleController.reset();
    } else {
      await sp.signInWithGoogle().then((value) {
        if (sp.hasError == true) {
          openSnackBar(context, sp.errorCode.toString(), Colors.red);
          googleController.reset();
        } else {
          // check whether the user is logged in or not
          sp.checkUserExists().then((value) async {
            if (value == true) {
              // user exists
              await sp.getUserDataFromFirestore(sp.uid).then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value) {
                        googleController.success();
                        handleAfterSignIn();
                      })));
            } else {
              // user does not exist
              sp.saveDataToFirestore().then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value) {
                        googleController.success();
                        // handleAfterSignIn
                      })));
            }
          });
        }
      });
    }
  }

  // handle after sign in
  handleAfterSignIn() {
    Future.delayed(const Duration(milliseconds: 1000)).then((value) {
      nextScreenReplace(context, const HomeScreen());
    });
  }
}

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    super.key,
    required this.size,
    required this.googleController,
    required this.icon,
    required this.text,
    required this.color,
    required this.function,
  });
  final Color color;
  final String text;
  final IconData icon;
  final Size size;
  final RoundedLoadingButtonController googleController;
  final VoidCallback function;

  @override
  Widget build(BuildContext context) {
    return RoundedLoadingButton(
      width: size.width * 0.8,
      elevation: 0,
      borderRadius: 25,
      controller: googleController,
      successColor: color,
      onPressed: function,
      color: color,
      child: Wrap(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            "Sign in with $text",
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
