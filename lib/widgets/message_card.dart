import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:wechat/api/apis.dart';
import 'package:wechat/helper/my_date_util.dart';
import 'package:wechat/models/messages.dart';

import '../helper/dialogs.dart';
import '../main.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Messages message;
  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = API.user.uid == widget.message.fromId;
    return InkWell(
      onLongPress: () {
        _showBottomSheet(isMe);
      },
      child: isMe ? _greenMessage() : _blueMessage(),
    );
  }

  //sender or another user message
  Widget _blueMessage() {
    //update last read message if sender and receiver are different
    if (widget.message.read.isEmpty) {
      API.updateMessageReadStatus(widget.message);
      log('message read updated');
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
          child: Container(
        padding: EdgeInsets.all(widget.message.type == Type.image
            ? mq.width * .03
            : mq.width * .04),
        margin: EdgeInsets.symmetric(
            horizontal: mq.width * .04, vertical: mq.height * .01),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 221, 245, 255),
            border: Border.all(color: Colors.lightBlue),
            //making borders curve
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30))),
        child: widget.message.type == Type.text
            ?
            //show text
            Text(
                widget.message.msg,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(
                    15), //half or greater than height and width to show in complete circular shape
                child: CachedNetworkImage(
                  imageUrl: widget.message.msg,
                  placeholder: (context, url) =>
                      CircularProgressIndicator(strokeWidth: 2),
                  errorWidget: (context, url, error) => Icon(
                    Icons.image,
                    size: 70,
                  ),
                ),
              ),
      )
          //show image

          ),
      Padding(
        padding: EdgeInsets.only(right: mq.width * .04),
        child: Text(
          MyDateUtil.getFormatedTime(
              context: context, time: widget.message.sent),
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      )
    ]);
  }

  //our or user message
  Widget _greenMessage() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        //for adding some space
        SizedBox(
          width: mq.width * .04,
        ),

        //double tick blue icon for message read
        if (widget.message.read.isNotEmpty)
          Icon(
            Icons.done_all_rounded,
            color: Colors.blue,
            size: 20,
          ),

        //for adding some space
        SizedBox(
          width: 2,
        ),
        //read time
        Text(
          MyDateUtil.getFormatedTime(
              context: context, time: widget.message.sent),
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ]),
      Flexible(
          child: Container(
        padding: EdgeInsets.all(widget.message.type == Type.image
            ? mq.width * .03
            : mq.width * .04),
        margin: EdgeInsets.symmetric(
            horizontal: mq.width * .04, vertical: mq.height * .01),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 235, 253, 216),
            border: Border.all(color: Colors.green),
            //making borders curve
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomLeft: Radius.circular(30))),
        child: widget.message.type == Type.text
            ? Text(
                widget.message.msg,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(
                    15), //half or greater than height and width to show in complete circular shape
                child: CachedNetworkImage(
                  imageUrl: widget.message.msg,
                  placeholder: (context, url) =>
                      CircularProgressIndicator(strokeWidth: 2),
                  errorWidget: (context, url, error) => Icon(
                    Icons.image,
                    size: 70,
                  ),
                ),
              ),
      ))
    ]);
  }

  //bottom sheet for modifying message details
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        builder: (_) {
          return ListView(
            shrinkWrap: true, //for setting hight of bottomsheet as wrapcontent
            children: [
              //black divider
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),
              widget.message.type == Type.text
                  ?
                  //copy option
                  _OptionItem(
                      icon: Icon(
                        Icons.copy_all_rounded,
                        color: Colors.blue,
                        size: 26,
                      ),
                      name: 'Copy Text',
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
                          log('data copied');
                          //for hiding bottomsheet
                          Navigator.pop(context);
                          Dialogs.showSnackbar(context, 'Text Copied!');
                        });
                      },
                    )
                  :
                  //Save option
                  _OptionItem(
                      icon: Icon(
                        Icons.download_rounded,
                        color: Colors.blue,
                        size: 26,
                      ),
                      name: 'Save Image',
                      onTap: () async {
                        try {
                          log('image url : ${widget.message.msg}');
                          await GallerySaver.saveImage(widget.message.msg,
                                  albumName: 'We chat')
                              .then((success) {
                            //for hiding bottomsheet
                            Navigator.pop(context);
                            if (success != null && success) {
                              Dialogs.showSnackbar(
                                  context, 'Image saved successfully');
                            }
                          });
                        } catch (e) {
                          log('error while saving image : $e');
                        }
                      }),

              if (isMe)
                //saperator or divider
                Divider(
                  color: Colors.black54,
                  endIndent: mq.width * .04,
                  indent: mq.width * .04,
                ),

              if (widget.message.type == Type.text && isMe)
                //edit option
                _OptionItem(
                  icon: Icon(
                    Icons.edit_note,
                    color: Colors.blue,
                    size: 26,
                  ),
                  name: 'Edit Message',
                  onTap: () {
                    //for hiding bottomsheet
                    Navigator.pop(context);
                    _showMessageUpdateDialog();
                  },
                ),

              if (isMe)
                //Delet option
                _OptionItem(
                  icon: Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 26,
                  ),
                  name: 'Delete Message',
                  onTap: () async {
                    await API.deleteMessage(widget.message).then((value) {
                      //for hiding bottomsheet
                      Navigator.pop(context);
                    });
                  },
                ),

              //saperator or divider
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              //send option
              _OptionItem(
                icon: Icon(
                  Icons.remove_red_eye,
                  color: Colors.blue,
                ),
                name:
                    'Sent At : ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}',
                onTap: () {},
              ),
              //read option
              _OptionItem(
                icon: Icon(
                  Icons.remove_red_eye,
                  color: Colors.green,
                ),
                name: widget.message.read.isEmpty
                    ? 'Read At : Not seen yet'
                    : 'Read At : ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}',
                onTap: () {},
              ),
            ],
          );
        });
  }

  //dialog for updating message content
  void _showMessageUpdateDialog() {
    String updateMessage = widget.message.msg;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: EdgeInsets.only(left: 24,right: 24,top: 20,bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Icon(
                  Icons.message,
                  color: Colors.blue,
                  size: 28,
                ),
                Text('Update Message'),
              ]),
              content: TextFormField(
                maxLines: null,
                onChanged: (value) => updateMessage = value,
                initialValue: updateMessage,
                decoration: InputDecoration(
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

            //update button
            MaterialButton(onPressed: (){
              //closes dialog
              Navigator.pop(context);
              API.updateMessage(widget.message, updateMessage);
            },
            child: Text('Update',
            style: TextStyle(color: Colors.blue,fontSize: 16),),)
          ],
        ));
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;
  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.only(
            left: mq.width * .05,
            top: mq.height * .015,
            bottom: mq.height * .015),
        child: Row(
          children: [
            icon,
            Flexible(
                child: Text(
              '      $name',
              style: TextStyle(
                  fontSize: 15, color: Colors.black54, letterSpacing: .5),
            ))
          ],
        ),
      ),
    );
  }
}
