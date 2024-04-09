import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wechat/api/apis.dart';
import 'package:wechat/helper/my_date_util.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/models/messages.dart';
import 'package:wechat/widgets/dialogs/profile_dialog.dart';

import '../main.dart';
import '../screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({Key? key, required this.user}) : super(key: key);

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
//last message inf (if null-->no message)
  Messages? _messages;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)));
        },
        child: StreamBuilder(
          stream: API.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Messages.fromJson(e.data())).toList() ?? [];

            if (list.isNotEmpty) {
              _messages = list[0];
            }
            return ListTile(
              //user profile picture
              // leading: CircleAvatar(child: Icon(CupertinoIcons.person),),
              leading:
              InkWell(
                onTap: (){
                  showDialog(context: context, builder: (_) => ProfileDialog(user: widget.user,));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height *
                      0.3), //half or greater than height and width to show in complete circular shape
                  child:
                  CachedNetworkImage(
                    width: mq.height * .055,
                    height: mq.height * .055,
                    imageUrl: widget.user.image,
                    // placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => CircleAvatar(
                      child: Icon(CupertinoIcons.person),
                    ),
                  ),
                ),
              ),

              //user name
              title: Text(widget.user.name),

              //last message
              subtitle: Text(
                _messages != null ?
                    _messages!.type == Type.image ? 'image' :
                _messages!.msg : widget.user.about,
                maxLines: 1,
              ),

              //last message time
              trailing: _messages == null
                  ? null //show nothing when no message is send
                  : _messages!.read.isEmpty && _messages!.fromId != API.user.uid
                      ?
                      //show for unread message
                      Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )
                      :
                  //message sent time
              Text(
                          MyDateUtil.getLastMessageTime(context: context, time: _messages!.sent),
                          style: TextStyle(color: Colors.black54),
                        ),
              // trailing: Text('12:00 pm',
              //   style: TextStyle(color: Colors.black54),),
            );
          },
        ),
      ),
    );
  }
}
