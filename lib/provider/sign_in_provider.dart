import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInProvider extends ChangeNotifier {
  // instance of firebaseauth, facebook and google
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseAuth facebookAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

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
    final GoogleSignInAccount? googleSignInAccount =
        await GoogleSignIn().signIn();

    if (googleSignInAccount != null) {
      // executing our authentication
      try {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // signing in to firebase user interface
        final User userDetails =
            (await firebaseAuth.signInWithCredential(credential)).user!;

        // now save our all values
        _name = userDetails.displayName;
        _email = userDetails.email;
        _imageUrl = userDetails.photoURL;
        _uid = userDetails.uid;
        _provider = 'Google';
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
}
