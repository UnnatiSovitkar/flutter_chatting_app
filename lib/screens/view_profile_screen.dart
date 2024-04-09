import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat/helper/dialogs.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/screens/auth/login_screen.dart';

import '../api/apis.dart';
import '../helper/my_date_util.dart';
import '../main.dart';

class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ViewProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        //add appbar
        appBar: AppBar(
          title: Text(widget.user.name),
        ),
        floatingActionButton:
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Joined On : ',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              MyDateUtil.getLastMessageTime(
                  context: context, time: widget.user.createdAt,showYear: true),
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.height * .05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                //for adding some space
                SizedBox(
                  width: mq.width,
                  height: mq.height * .03,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height *
                      0.1), //half or greater than height and width to show in complete circular shape
                  child: CachedNetworkImage(
                    width: mq.height * .2,
                    height: mq.height * .2,
                    fit: BoxFit.fill, //covering entire space
                    imageUrl: widget.user.image,
                    // placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => CircleAvatar(
                      child: Icon(CupertinoIcons.person),
                    ),
                  ),
                ),

                //for adding some space
                SizedBox(
                  height: mq.height * .03,
                ),

                Text(
                  widget.user.email,
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                //for adding some space
                SizedBox(
                  height: mq.height * .02,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'About : ',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      widget.user.about,
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
