
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wechat/helper/dialogs.dart';
import 'package:wechat/screens/home_screen.dart';

import '../../api/apis.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimated = false;
  
  //giving delay of half seconds to open page
  @override
  void initState() {
    // TODO: implement initState
    Future.delayed(Duration(milliseconds: 500),(){

      _isAnimated = true;
      log('$_isAnimated');

    });
    super.initState();
  }

  _handleGoogleBtnClick(){
    //for showing progressbar
    Dialogs.showProgressbar(context);
    _signInWithGoogle().then((user) async {
      // dismiss progressbar
      Navigator.pop(context);

      if(user != null){

        log('\nuser:${user.user}');
        log('\nuser additionalinfo : ${user.additionalUserInfo}');


        if(await API.userExists()){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const HomeScreen()));
        }
        else{
          await API.createUser().then((value){

            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const HomeScreen()));

          });
        }
      }
      else{
        log('\nuser: something went wrong!');

      }

    });
  }

  Future<UserCredential?> _signInWithGoogle() async { //? means function can be return null

    try{

      await InternetAddress.lookup('google.com');//checking availability of internet

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await API.auth.signInWithCredential(credential);


    }catch(e){
      log('\n signin with google:$e');
      Dialogs.showSnackbar(context, 'Something went wrong(Check Internet!)');
      return null;

    }

  }
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    // mq = MediaQuery.of(context).size;

    return Scaffold(
      //add appbar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Welcome to We Chat'),
      ),

      body: Stack(children: [
        AnimatedPositioned(
            duration: Duration(seconds: 2),
            top: mq.height *.15,
            right: _isAnimated ? mq.width *.25 : - mq.width *.5,
            width: mq.width *.5,
            child: Image.asset('images/wechat.png')),

        Positioned(
            bottom: mq.height *.15,
            left: mq.width *.05,
            width: mq.width *.9,
            height: mq.height *.06,
            child: ElevatedButton.icon(
                style : ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 223, 255, 187),
                  shape: const StadiumBorder(),
                  elevation: 1),
                onPressed: (){
                  _handleGoogleBtnClick();
                },
                icon: Image.asset('images/google.png',height: mq.height *.04,),
                label: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Colors.black,fontSize: 16
                    ),
                    children: [
                      TextSpan(text: 'LogIn With '),
                      TextSpan(text: 'Google',
                          style: TextStyle(fontWeight: FontWeight.w700

                      ))
                    ]
                  ),
                )))
      ],),
    );
  }
}
