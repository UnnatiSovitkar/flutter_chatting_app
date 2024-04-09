import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat/helper/my_date_util.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/screens/view_profile_screen.dart';
import 'package:wechat/widgets/message_card.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/messages.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for storing all messages
  List<Messages> _list = [];

  //for handling message text changes
  final _textController = TextEditingController();
  //_showEmogi ---for storing value of showing or hiding emojis
  //_isUploading ---for is image uploading or not
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          //if emojis are shown and back button is pressed then hide emojis
          //or else simple close current screen on back button click
          onWillPop: () {
            if (_showEmoji) {
              setState(() {
                _showEmoji = !_showEmoji;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appbar(),
            ),
            //body
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: API.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return SizedBox();

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          // log('data : ${jsonEncode(data![0].data())}');
                          // // for(var i in data!){
                          // //   log('Data: ${jsonEncode(i.data())}');
                          // //   list.add(i.data()['name']);
                          // // }

                          //fetching firebase data and adding to model class
                          _list = data
                                  ?.map((e) => Messages.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                                reverse: true,
                                itemCount: _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(message: _list[index]);
                                });
                          } else {
                            return Center(
                                child: Text(
                              'Say Hii! 👋',
                              style: TextStyle(fontSize: 20),
                            ));
                          }
                      }
                    },
                  ),
                ),
                //progress indicator for uploading
                if (_isUploading)
                  Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )),
                _chatInput(),
                //show Emojis on keyboard btnclick or vice versa
                if (_showEmoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController:
                          _textController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
                      config: Config(
                        // bgColor: Colors.white70,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          // Issue: https://github.com/flutter/flutter/issues/28894
                          emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                        ),
                        swapCategoryAndBottomBar: false,
                        skinToneConfig: const SkinToneConfig(),
                        categoryViewConfig: const CategoryViewConfig(),
                        bottomActionBarConfig: const BottomActionBarConfig(),
                        searchViewConfig: const SearchViewConfig(),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  //appbar
  Widget _appbar() {
    return InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(user: widget.user,)));
        },
        child: StreamBuilder(
          stream: API.getUserInfo(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            log('data : ${data}');
            final list =
                data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
            log('List : ${list[0]}');
            return
              Row(
              children: [
                //back button
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.black54,
                    )),

                //user profile picture
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height *
                      .03), //half or greater than height and width to show in complete circular shape
                  child: CachedNetworkImage(
                    width: mq.height * .05,
                    height: mq.height * .05,
                    fit: BoxFit.fill, //covering entire space
                    imageUrl:
                        list.isNotEmpty ? list[0].image : widget.user.image,
                    // placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => CircleAvatar(
                      child: Icon(CupertinoIcons.person),
                    ),
                  ),
                ),
                //for adding some space
                SizedBox(width: 10),

                //user name and last seen time
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //user name
                    Text(
                      list.isNotEmpty ? list[0].name : widget.user.name,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500),
                    ),

                    //for adding some space
                    SizedBox(
                      height: 2,
                    ),

                    //last seen time of user
                    Text(
                      list.isNotEmpty
                          ? list[0].isOnline
                              ? 'Online'
                              : MyDateUtil.getLastActiveTime(context: context, lastActive: list[0].lastActive)
                          : MyDateUtil.getLastActiveTime(context: context, lastActive: list[0].lastActive),
                      // 'Last seen not available',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    )
                  ],
                ),
              ],
            );
          },
        ));
  }

  // Widget _chatInput(){
  //   return Expanded(
  //     child: Padding(
  //       padding: EdgeInsets.symmetric(
  //           vertical: mq.height *.01,
  //           horizontal: mq.width *.25),
  //       child: Row(
  //         children: [
  //           //input fields and buttons
  //           Flexible(
  //             flex: 1,
  //             fit: FlexFit.tight,
  //             child: Card(
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //               child: Row(
  //                 children: [
  //                   //emoji button
  //                   IconButton(onPressed: (){
  //                   }, icon: Icon(Icons.emoji_emotions,color: Colors.pink,size: 25)),
  //
  //                   Expanded(child: TextField(
  //                     keyboardType: TextInputType.multiline,
  //                     maxLines: null,
  //                     decoration: InputDecoration(
  //                       hintText: 'Type Something...',
  //                       hintStyle: TextStyle(color: Colors.pink,),
  //                       border: InputBorder.none,
  //                     ),
  //                   )),
  //                   //gallery button
  //                   IconButton(onPressed: (){
  //                   }, icon: Icon(Icons.image,color: Colors.pink,size: 26)),
  //
  //                   //camera button
  //                   IconButton(onPressed: (){
  //                   }, icon: Icon(Icons.camera_alt_rounded,color: Colors.pink,size: 26)),
  //                   //adding some space
  //                   SizedBox(width: mq.width * .02,),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           //send message button
  //           Flexible(
  //             flex: 1,
  //             fit: FlexFit.tight,
  //             child: MaterialButton(onPressed: (){},
  //               shape: CircleBorder(),
  //               minWidth: 0,
  //               padding: EdgeInsets.only(bottom: 10,top: 10,left: 10,right: 5),
  //               color: Colors.green,
  //             child: Icon(Icons.send,color: Colors.white,size: 28,),),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _chatInput() {
    return Container(
      margin: EdgeInsets.all(mq.width * .05),
      child: Row(
        // mainAxisSize: MainAxisSize.max,
        // mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Padding(padding: EdgeInsets.only(left: 5,right: 10)),
          //input fields and buttons
          Flexible(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  //emoji button
                  Expanded(
                    flex: 1,
                    child: IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _showEmoji = !_showEmoji);
                        },
                        icon: Icon(Icons.emoji_emotions,
                            color: Colors.pink, size: 25)),
                  ),

                  Expanded(
                    flex: 3,
                    child: Container(
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onTap: () {
                          if (_showEmoji)
                            setState(() => _showEmoji = !_showEmoji);
                        },
                        decoration: InputDecoration(
                          hintText: 'Type Something...',
                          hintStyle: TextStyle(
                            color: Colors.pink,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  //gallery button
                  Expanded(
                    flex: 1,

                    //pick image from gallary
                    child: IconButton(
                        onPressed: () async {
                          final ImagePicker picker =
                              ImagePicker(); // Pick an image.
                          //picking multiple images
                          final List<XFile> images =
                              await picker.pickMultiImage(imageQuality: 70);
                          //uploading and sending image one by one
                          for (var i in images) {
                            log('image path : ${i.path}');
                            setState(() => _isUploading = true);
                            await API.sendChatImage(widget.user, File(i.path));
                            setState(() => _isUploading = false);
                          }
                        },
                        icon: Icon(Icons.image, color: Colors.pink, size: 26)),
                  ),

                  //camera button
                  Expanded(
                    flex: 1,
                    //pick image from camera
                    child: IconButton(
                        onPressed: () async {
                          final ImagePicker picker =
                              ImagePicker(); // Pick an image.
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.camera, imageQuality: 70);

                          if (image != null) {
                            log('image path : ${image.path}');
                            setState(() => _isUploading = true);

                            //for upading image with gallary image
                            await API.sendChatImage(
                                widget.user, File(image.path));
                            setState(() => _isUploading = false);
                          }
                        },
                        icon: Icon(Icons.camera_alt_rounded,
                            color: Colors.pink, size: 26)),
                  ),
                  //adding some space
                  SizedBox(
                    width: mq.width * .02,
                  ),
                ],
              ),
            ),
          ),
          //send message button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                //on first message(add user to my_user collection of chat user)
                if(_list.isEmpty){
                  API.sendFirstMessage(widget.user, _textController.text, Type.text);
                }else{
                  //simply send message
                  API.sendMessage(widget.user, _textController.text, Type.text);
                }
                _textController.text = '';
              }
            },
            shape: CircleBorder(),
            minWidth: 0,
            padding: EdgeInsets.only(bottom: 10, top: 10, left: 10, right: 5),
            color: Colors.green,
            child: Icon(
              Icons.send,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
