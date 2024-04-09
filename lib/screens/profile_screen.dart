
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat/helper/dialogs.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/screens/auth/login_screen.dart';

import '../api/apis.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        //add appbar
        appBar: AppBar(
          title: Text('Profile Screen'),
        ),

        //floating button to add new user
        floatingActionButton: Padding(
          padding:  EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              //show progress dialog
              Dialogs.showProgressbar(context);
              //during logout update active status to false
              await API.updateActiveStatus(false);
              //logout googlesignin
              await API.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  //for hiding progress dialog
                  Navigator.pop(context);
                  API.auth = FirebaseAuth.instance;
                  //for moving to home screen
                  Navigator.pop(context);
                  //replacing home screen with Login screen
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                });
              });

            },
            icon: Icon(Icons.logout),
            label: Text('Logout'),
          ),
        ),
        body:Form(
          //key is used to check validation
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.height*.05),
            child: SingleChildScrollView(
              child: Column(children: [
                //for adding some space
                SizedBox(width: mq.width,height: mq.height*.03,),

                Stack(
                  children: [
                    //profile picture

                    _image != null ?
                ClipRRect(
                borderRadius: BorderRadius.circular(mq.height*0.1),//half or greater than height and width to show in complete circular shape
                       child: Image.file(File(_image!),
                        width: mq.height*.2,
                        height: mq.height*.2,
                        fit: BoxFit.cover,//covering entire space
                        ),)
                        :
                    ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height*0.1),//half or greater than height and width to show in complete circular shape
                      child: CachedNetworkImage(
                        width: mq.height*.2,
                        height: mq.height*.2,
                        fit: BoxFit.fill,//covering entire space
                        imageUrl: widget.user.image,
                        // placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person),
                        ),),
                    ),
                    //edit button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: MaterialButton(onPressed: (){
                        _showBottomSheet();
                      },
                      child: Icon(Icons.edit,color: Colors.blue),
                        shape: CircleBorder(),
                      color: Colors.white,),
                    )
                  ],
                ),

                //for adding some space
                SizedBox(height: mq.height*.03,),

                Text(widget.user.email,style: TextStyle(color: Colors.black54,fontSize: 16),),

                //for adding some space
                SizedBox(height: mq.height*.05,),

                TextFormField(
                  initialValue: widget.user.name,
                  onSaved: (val) => API.me.name = val ?? '',
                  validator: (val) => val != null && val.isNotEmpty ? null : 'Required Field',
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person,color:Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'eg. Happy Singh',
                    label: Text('Name'),
                  ),
                ),

                //for adding some space
                SizedBox(height: mq.height*.02,),

                TextFormField(
                  initialValue: widget.user.about,
                  onSaved: (val) => API.me.about = val ?? '',
                  validator: (val) => val != null && val.isNotEmpty ? null : 'Required Field',
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.info_outline,color: Colors.blue,),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'eg. Feeling Happy',
                    label: Text('About'),
                  ),
                ),

                //for adding some space
                SizedBox(height: mq.height*.05,),

                ElevatedButton.icon(onPressed: (){
                  if(_formKey.currentState!.validate()){
                    _formKey.currentState!.save();
                    API.updateUserInfo();
                    Dialogs.showSnackbar(context, 'Profile Updated Successfully!');
                    log('inside validator');
                  }
                },
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    minimumSize: Size(mq.width * .5, mq.height * .06),
                  ),
                  icon: Icon(Icons.edit),
                  label: Text('Update',style: TextStyle(fontSize: 16),),
                    )

              ],),
            ),
          ),
        ),

      ),
    );
  }
  //bottom sheet for picking a profile picture for user
  void _showBottomSheet(){
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),topRight: Radius.circular(20)),
        ),
        builder: (_){
          return ListView(
            shrinkWrap: true,//for setting hight of bottomsheet as wrapcontent
            padding: EdgeInsets.only(top: mq.height * .03,bottom: mq.height*.05),
          children: [
            Text('Pick Profile Picture',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20,fontWeight: FontWeight.w500),),

            //for addong some space
            SizedBox(height: mq.height * .02,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: CircleBorder(),
                      fixedSize: Size(mq.width * .3, mq.height * .15),
                    ),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();// Pick an image.
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery,imageQuality: 80);

                      if(image != null){
                        log('image path : ${image.path} --Mime : ${image.mimeType}');
                        setState(() {
                          _image = image.path;
                        });
                        //for upading image with gallary image
                        API.updateProfilePicture(File(_image!));
                        Navigator.pop(context);//to close bottomsheet
                      }
                    },
                    child: Image.asset('images/gallery.png')),

                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: CircleBorder(),
                      fixedSize: Size(mq.width * .3, mq.height * .15),
                    ),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();// Pick an image.
                      final XFile? image = await picker.pickImage(source: ImageSource.camera , imageQuality: 80);

                      if(image != null){
                        log('image path : ${image.path}');
                        setState(() {
                          _image = image.path;
                        });
                        //for upading image with gallary image
                        API.updateProfilePicture(File(_image!));
                        Navigator.pop(context);//to close bottomsheet
                      }
                    },
                    child: Image.asset('images/camera.png'))

              ],
            )
          ],
          );
        });
  }
}
