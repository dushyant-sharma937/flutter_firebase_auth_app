import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twitter_login/twitter_login.dart';

import '../utils/config.dart';

class SignInProvider extends ChangeNotifier {
  // instance of firebaseauth, facebook and google
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseAuth facebookAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final twitterLogin = TwitterLogin(
      apiKey: Config.apikey_twitter,
      apiSecretKey: Config.secretkey_twitter,
      redirectURI: "socialauth://");

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  // has error, errorCode, provider, uid, email, name, imageUrl
  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorCode;
  String? get errorCode => _errorCode;

  String? _provider;
  String? get provider => _provider;

  String? _uid;
  String? get uid => _uid;

  String? _email;
  String? get email => _email;

  String? _name;
  String? get name => _name;

  String? _imageUrl;
  String? get imageUrl => _imageUrl;

  SignInProvider() {
    checkSignInUser();
  }

  Future checkSignInUser() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _isSignedIn = s.getBool('signed_in') ?? false;
    notifyListeners();
  }

  Future setSignIn() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    s.setBool('signed_in', true);
    _isSignedIn = true;
    notifyListeners();
  }

  // sign in with google

  Future signInWithGoogle() async {
    // Here GoogleSignInAccount will store the user account.
    final GoogleSignInAccount? googleSignInAccount =
        await GoogleSignIn().signIn();

    // if we have our user account, then only we will further process with the information otherwise not.
    if (googleSignInAccount != null) {
      // executing our authentication
      try {
        // here GoogleSignInAuthentication will holds the tokens for sign in.
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        // Here we will store the user credentials with the help of those tokens
        // which are stored in GoogleSignInAuthentication and use these credentials
        // further to sign in to firebase user interface.
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // signing in to firebase user interface
        // here we will sign in to firebase by using the credentials we got from
        // our user google account.
        final User userDetails =
            (await firebaseAuth.signInWithCredential(credential)).user!;

        // now save our all values
        _name = userDetails.displayName;
        _email = userDetails.email;
        _imageUrl = userDetails.photoURL;
        _uid = userDetails.uid;
        _provider = 'Google';
        _hasError = false;
        notifyListeners();
      } on FirebaseAuthException catch (err) {
        switch (err.code) {
          case "account-exists-with-different-credential":
            _errorCode =
                'Your already have an account with us. Use correct credentials';
            _hasError = true;
            notifyListeners();
            break;
          case "null":
            _errorCode = 'Some error occurred while trying to sign in';
            _hasError = true;
            notifyListeners();
            break;
          default:
            _errorCode = err.toString();
            _hasError = true;
            notifyListeners();
        }
      }
    } else {
      _hasError = true;
      notifyListeners();
    }
  }

  // check whether user exists or not in cloudfirestore
  Future<bool> checkUserExists() async {
    DocumentSnapshot snap =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    if (snap.exists) {
      print('Existing user');
      return true;
    } else {
      print('New user');
      return false;
    }
  }

  Future getUserDataFromFirestore(uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .then((DocumentSnapshot snapshot) => {
              _name = snapshot['name'],
              _email = snapshot['email'],
              _imageUrl = snapshot['imageUrl'],
              _uid = snapshot['uid'],
              _provider = snapshot['provider']
            });
  }

  Future saveDataToFirestore() async {
    final DocumentReference r =
        FirebaseFirestore.instance.collection('users').doc(uid);
    await r.set({
      "name": _name,
      "email": _email,
      "imageUrl": _imageUrl,
      "uid": _uid,
      "provider": _provider,
    });
    notifyListeners();
  }

  Future saveDataToSharedPreferences() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    await s.setString('name', _name!);
    await s.setString('email', _email!);
    await s.setString('imageUrl', _imageUrl!);
    await s.setString('uid', _uid!);
    await s.setString('provider', _provider!);
  }

  Future getDataFromSharedPreferences() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _name = s.getString('name');
    _email = s.getString('email');
    _imageUrl = s.getString('imageUrl');
    _uid = s.getString('uid');
    _provider = s.getString('provider');
    notifyListeners();
  }

  Future userSignOut() async {
    await googleSignIn.signOut();
    await firebaseAuth.signOut;
    _isSignedIn = false;
    notifyListeners();

    // clear all data
    clearStoredData();
  }

  Future clearStoredData() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    s.clear();
  }

  Future signInWithTwitter() async {
    final authResult = await twitterLogin.loginV2();

    if (authResult.status == TwitterLoginStatus.loggedIn) {
      // authentication successful
      try {
        final credential = TwitterAuthProvider.credential(
            accessToken: authResult.authToken!,
            secret: authResult.authTokenSecret!);
        await firebaseAuth.signInWithCredential(credential);

        final userDetails = authResult.user;
        // save all the user details
        _name = userDetails!.name;
        _email = firebaseAuth.currentUser?.email ?? "test@gmail.com";
        _imageUrl = userDetails.thumbnailImage;
        _uid = userDetails.id.toString();
        _provider = 'TWITTER';
        _hasError = false;
        notifyListeners();
      } on FirebaseAuthException catch (err) {
        switch (err.code) {
          case "account-exists-with-different-credential":
            // _errorCode =
            //     'Your already have an account with us. Use correct credentials';
            // _hasError = true;
            // notifyListeners();

            // The account already exists with a different credential
            String email = err.email!;
            // AuthCredential pendingCredential = err.credential!;

            // Fetch a list of what sign-in methods exist for the conflicting user
            List<String> userSignInMethods =
                await firebaseAuth.fetchSignInMethodsForEmail(email);

            // If the user has several sign-in methods,
            // the first method in the list will be the "recommended" method to use.
            if (userSignInMethods == 'google.com') {
              return signInWithGoogle();
            }
            break;
          case "null":
            _errorCode = 'Some error occurred while trying to sign in';
            _hasError = true;
            notifyListeners();
            break;
          default:
            _errorCode = err.toString();
            _hasError = true;
            notifyListeners();
        }
      }
    } else {
      _hasError = true;
      notifyListeners();
    }
  }

  void phoneNumberUser(User user, email, name) {
    _name = name;
    _email = email;
    _uid = user.phoneNumber;
    _imageUrl =
        "https://w7.pngwing.com/pngs/184/113/png-transparent-user-profile-computer-icons-profile-heroes-black-silhouette-thumbnail.png";
    _provider = 'PHONE';
    notifyListeners();
  }
}
