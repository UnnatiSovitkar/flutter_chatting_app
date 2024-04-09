import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

import 'package:wechat/models/chat_user.dart';
import 'package:wechat/models/messages.dart';

class API {
  //for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  //for accessing cloud firesore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //for accessing cloud firesore database
  static FirebaseStorage storage = FirebaseStorage.instance;

  //for accessing firebase messaging (push notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  //for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();
    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('pushToken : $t');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('\nGot a message whilst in the foreground!');
      log('\nMessage data: ${message.data}');

      if (message.notification != null) {
        log('\nMessage also contained a notification: ${message.notification}');
      }
    });
  }

  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    final body = {
      "to": chatUser.pushToken,
      "notification": {
        "title": chatUser.name,
        "body": msg,
        "android_channel_id": "chats",
      },
      "data": {
        "some_data" : "User Id : ${me.id}",
      },
    };

    var res = await post(Uri.parse('https://fcm.googleapis.com/v1/projects/we-chat-ac9b7/messages:send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              'key=AAAARrKUCQc:APA91bFxCmQNc-8zcWOPVJFzsAoe0EKQxfP3bGfKgTLuu1yTl5OTVmz_0Qje3nHdF1yS-_nGPLz-Dfq0dfwqt1qqOKpXjAi-N2UcHJ8-K912zcLP0OGVx1tvQqD9_iwbuXuJYXnqRato'
        },
        body: jsonEncode(body));
    print('Response status: ${res.statusCode}');
    print('Response body: ${res.body}');
  }

  //to return current user
  static User get user => auth.currentUser!; //! means should not null

  //global variable for storing self information
  static late ChatUser me;
  //for checking if user is exist or not ?
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  //for adding a chatuser for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore.collection('users').where('email',isEqualTo: email).get();
    log('data : ${data}');
    if(data.docs.isNotEmpty && data.docs.first.id != user.uid){
      //user exist
      firestore.collection('users')
      .doc(user.uid)
      .collection('my_users')
      .doc(data.docs.first.id)
      .set({});

      log('user exist : ${data.docs.first.data()}');

      return true;
    }
    else{
      //user doesn't exists
      return false;
    }
  }

  //for getting current user info
  static Future<void> getSelfInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .then((user) async => {
              if (user.exists)
                {
                  me = ChatUser.fromJson(user.data()!),
                  getFirebaseMessagingToken(),
                  //for setting user status to active
                  API.updateActiveStatus(true),

                  log('My Data ${user.data()}')
                }
              else
                {await createUser().then((value) => getSelfInfo())}
            });
  }

  //for creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
        image: user.photoURL.toString(),
        about: "Hey , I'm using We Chat!",
        name: user.displayName.toString(),
        createdAt: time,
        id: user.uid.toString(),
        lastActive: time,
        isOnline: false,
        pushToken: '',
        email: user.email.toString());

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }
  //for getting ids of known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersIds() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  //for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(List<String> userIds) {
    log('\nuserIds : $userIds');
    return firestore
        .collection('users')
        .where('id', whereIn: userIds)

        // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }
  //for adding a user to my user when first message is sent
  static Future<void> sendFirstMessage(ChatUser chatUser,String msg,Type type) async {
    (await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_user')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type)));
  }

  //for updating user info
  static Future<void> updateUserInfo() async {
    (await firestore
        .collection('users')
        .doc(user.uid)
        .update({'name': me.name, 'about': me.about}));
  }

  //for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  //update online or last update status
  static Future<void> updateActiveStatus(bool isOnline) async {
    (await firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken
    }));
  }

  // update profile picture of user
  static Future<void> updateProfilePicture(File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;
    log('extension : $ext');

    //storage file ref with path
    final ref = storage.ref().child('profile_picture/${user.uid}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferd : ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firebase database
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  ///******************Chat Screen Related Apis********************///
//chat(collection)--> conversation_id (doc)-->message(collection)-->message(doc)

  //useful for getting conversation id
  static String getConversationId(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

//for getting all messages of specific conversation from firebase database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationId(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  //for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    //message sending time(also used as id )
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    //message to send
    final Messages message = Messages(
        msg: msg,
        toId: chatUser.id,
        read: '',
        type: type,
        sent: time,
        fromId: user.uid);
    final ref = firestore
        .collection('chats/${getConversationId(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson());

    // await ref.doc(time).set(message.toJson()).then((value) => sendPushNotification(chatUser, type == Type.text ? msg :'image'));
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Messages messages) async {
    firestore
        .collection('chats/${getConversationId(messages.fromId)}/messages/')
        .doc(messages.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationId(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send chat image
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;

    //storage file ref with path
    final ref = storage.ref().child(
        'images/${getConversationId(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //upload image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //uploading image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  //delete message
  static Future<void> deleteMessage(Messages message) async {
    await firestore
        .collection('chats/${getConversationId(message.toId)}/messages/')
        .doc(message.sent)
        .delete();
    if(message.type == Type.image){
      await storage.refFromURL(message.msg).delete();
    }
  }
  //update message
  static Future<void> updateMessage(Messages message,String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationId(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
    
  }
  }
