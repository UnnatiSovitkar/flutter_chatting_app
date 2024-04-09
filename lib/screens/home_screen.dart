


import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wechat/helper/dialogs.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/screens/profile_screen.dart';
import 'package:wechat/widgets/chat_user_card.dart';
import '../api/apis.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //for storing all users
  List<ChatUser> _list = [];
  //for storing search users
  final List<ChatUser> _searchList = [];
  //for storing search status
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    API.getSelfInfo();
    //for updating users active status according to lifecycle events
    //resume -- active or online
    //pause -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message){
      log('$message');
      if(API.auth.currentUser != null){
        if(message.toString().contains('resume')) API.updateActiveStatus(true);
        if(message.toString().contains('pause')) API.updateActiveStatus(false);

      }
      return Future.value(message);
    });
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard when a tap is detected on screen
      onTap: ()=> FocusScope.of(context).unfocus(),
      child: WillPopScope(
        //if search is on and back button is pressed then close search
        //or else simple close current screen on back button click
        onWillPop: () {
          if(_isSearching){
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          }
          else{
            return Future.value(true);
          }
        },

        child: Scaffold(
          //add appbar
          appBar: AppBar(
            leading: Icon(CupertinoIcons.home),
            title: _isSearching ? TextField(
              decoration: InputDecoration(border: InputBorder.none,hintText: 'Name,Email..',),
              autofocus: true,
              style: TextStyle(fontSize: 17,letterSpacing: 0.5),
              //when search text changes and updated search list
              onChanged: (val){
                //search logic
                _searchList.clear();
                for(var i in _list){
                  if(i.name.toLowerCase().contains(val.toLowerCase()) ||
                  i.email.toLowerCase().contains(val.toLowerCase())){
                    _searchList.add(i);
                  }
                  setState(() {
                    _searchList;
                  });

                }
              },
            ) : Text('We Chat'),
            actions: [
              //search user button
              IconButton(onPressed: (){
                setState(() {
                  _isSearching = !_isSearching;
                });
              }, icon: Icon(
                  _isSearching ? CupertinoIcons.clear_circled_solid:Icons.search)),
              //more features button
              IconButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>ProfileScreen(user: API.me)));
              }, icon: Icon(Icons.more_vert)),
            ],
          ),

          //floating button to add new user
          floatingActionButton: Padding(
            padding:  EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: ()  {
                _addChatUserDialog();
              }, child: Icon(Icons.insert_comment_rounded),
            ),
          ),
          body:
          StreamBuilder(
            stream: API.getMyUsersIds(),
            //get ids of only known users
            builder: (context, snapshot) {
              switch(snapshot.connectionState){
              //if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return Center(child: CircularProgressIndicator());

              //if some or all data is loaded then show it
                case ConnectionState.active:
                case ConnectionState.done:

              return StreamBuilder(
                stream: API.getAllUsers(snapshot.data?.docs.map((e) => e.id).toList() ?? []),

                //get only those users whose ids are provided
                builder:(context,snapshot){
                  switch(snapshot.connectionState){
                  //if data is loading
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      // return Center(child: CircularProgressIndicator());

                  //if some or all data is loaded then show it
                    case ConnectionState.active:
                    case ConnectionState.done:


                      final data = snapshot.data?.docs;
                      // for(var i in data!){
                      //   log('Data: ${jsonEncode(i.data())}');
                      //   list.add(i.data()['name']);
                      // }
                      //fetching firebase data and adding to model class
                      _list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];


                      if(_list.isNotEmpty){
                        return ListView.builder(
                            itemCount: _isSearching ? _searchList.length : _list.length,
                            padding: EdgeInsets.only(top: mq.height * .01),
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (context, index){
                              return  ChatUserCard(user: _isSearching ? _searchList[index] : _list[index]);
                              //   return Text('Name : ${list[index]}');
                            }
                        );
                      }
                      else{
                        return Center(child: Text('No Connection found!', style:TextStyle(fontSize: 20),));
                      }
                  }
                },);
            }
          },),
        ),
      ),
    );
  }

  //for adding new chatuser
  void _addChatUserDialog() {
    String email = '';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: EdgeInsets.only(left: 24,right: 24,top: 20,bottom: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(
              Icons.person_add,
              color: Colors.blue,
              size: 28,
            ),
            Text('  Add User'),
          ]),
          content: TextFormField(
            maxLines: null,
            onChanged: (value) => email = value,
            decoration: InputDecoration(
              hintText: 'Email Id',
              prefix: Icon(Icons.email,color: Colors.blue,),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15)),),
          ),
          //actions
          actions: [
            //cancel action
            MaterialButton(onPressed: (){
              //closes dialog
              Navigator.pop(context);
            },
              child: Text(
                'cancel',
                style: TextStyle(color: Colors.blue,fontSize: 16),
              ),),

            //add button
            MaterialButton(onPressed: () async {
              //closes dialog
              Navigator.pop(context);
              if(email.isNotEmpty) {
                await API.addChatUser(email).then((value) => {
                  if(!value){
                    Dialogs.showSnackbar(context, 'User does not Exists!')
                  }
                });
              }
            },
              child: Text('Add',
                style: TextStyle(color: Colors.blue,fontSize: 16),),)
          ],
        ));
  }

}
