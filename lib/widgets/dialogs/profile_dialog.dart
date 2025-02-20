import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/screens/view_profile_screen.dart';

import '../../main.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white.withOpacity(.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: mq.width * .6,
        height: mq.height * .35,

        child: Stack(
          children: [
            //user profile picture
            Positioned(
              left: mq.width * .1,
              top: mq.height * .065,

              child: ClipRRect(
                borderRadius: BorderRadius.circular(mq.height *
                    0.2), //half or greater than height and width to show in complete circular shape
                child: CachedNetworkImage(
                  width: mq.height * .25,
                  height: mq.height * .25,
                  fit: BoxFit.fill, //covering entire space
                  imageUrl: user.image,
                  // placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => CircleAvatar(
                    child: Icon(CupertinoIcons.person),
                  ),
                ),
              ),
            ),
            //user name
            Positioned(
              left: mq.width * .04,
              top: mq.height * .02,
              width: mq.width * .55,
              child: Text(
                user.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            //Info button
            Positioned(
              right: 8,
              top: 6,
              child: MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_)=> ViewProfileScreen(user: user)));
                },
                minWidth: 0,
                padding: EdgeInsets.all(0),
                shape: CircleBorder(),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
