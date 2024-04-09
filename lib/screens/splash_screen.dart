import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wechat/screens/auth/login_screen.dart';
import 'package:wechat/screens/home_screen.dart';
import '../../main.dart';
import '../api/apis.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  //giving delay of half seconds to open page
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Timer(Duration(seconds: 2), () {
      //exit full screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white, statusBarColor: Colors.white
      ));

      if(API.auth.currentUser != null){

        log('\nuser:${API.auth.currentUser}');
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context)=>
                HomeScreen())
        );
      }
      else{

        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context)=>
                LoginScreen())
        );
      }



    });


  }
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      //add appbar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Welcome to We Chat'),
      ),
      body: Stack(children: [
        Positioned(
            top: mq.height *.15,
            right: mq.width *.25 ,
            width: mq.width *.5,
            child: Image.asset('images/wechat.png')),

        Positioned(
            bottom: mq.height *.15,
            width: mq.width ,
            child: Text('MADE IN INDIA WITH ❤️',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16,
            color: Colors.black87,
            letterSpacing: .5,
            ),))
      ],),
    );
  }
}
