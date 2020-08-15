import 'dart:io';
import 'dart:async';

import 'package:msging/constants.dart';

import 'package:bubble/bubble.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main(){
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]).then((_){
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Msging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState(){
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> scaffoldKeyLoginPage = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> scaffoldKeySignUpPage = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> scaffoldKeyUserHomePage = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> scaffoldKeyForgotPasswordPage = new GlobalKey<ScaffoldState>();

  int state;
  int userState=USER_STATE_HOME;

  @override
  void initState() {
    super.initState();
    getUser().then((FirebaseUser user) {
      setState(() {
        state=STATE_USER;
      });
    }).catchError((error) {
      setState(() {
        state=STATE_LOGIN;
      });
    });
  }

  @override
  Widget build(BuildContext context){
    if(state==STATE_LOGIN){
      return getLoginPage();
    }
    else if(state==STATE_SIGN_UP){
      return getSignUpPage();
    }
    else if(state==STATE_FORGOT_PASSWORD){
      return getForgotPasswordPage();
    }
    else if(state==STATE_USER){
      return FutureBuilder(
        future: getUser(),
        builder: (BuildContext context,AsyncSnapshot snapshot){
          if(snapshot.hasData){
            return getUserPage(snapshot.data);
          }
          else{
            return getLoadingPage();
          }
        },
      );
    }
    else{
      return getLoadingPage();
    }
  }

  Widget getLoginPage(){
    final emailController = new TextEditingController();
    final passwordController = new TextEditingController();
    return Scaffold(
      key: scaffoldKeyLoginPage,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar:AppBar(
        title: Text('Login'),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage('assets/images/login_background.jpg'),
            )
        ),
        padding: EdgeInsets.fromLTRB(40,20,40,20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Image(
              height: 90,
              width: 90,
              image: AssetImage('assets/images/login_icon.png'),
            ),
            SizedBox(
              height: 10,
            ),
            TextField(
              textInputAction: TextInputAction.none,
              controller: emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                labelText: 'Email',
              ),
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
              textInputAction: TextInputAction.none,
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                labelText: 'Password',
              ),
            ),
            SizedBox(
              height: 20,
            ),
            FlatButton(
              child: Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.lightBlueAccent,
              onPressed: (){
                FocusScope.of(context).requestFocus(new FocusNode());
                String email = emailController.text.trim().toLowerCase();
                String password = passwordController.text;
                if(email.isEmpty || password.isEmpty){
                  Fluttertoast.showToast(msg: 'ONE OR MORE FIELDS EMPTY');
                }
                else{
                  showSnackBar(scaffoldKeyLoginPage,'Loading...');
                  signIn(email, password).then((FirebaseUser user){
                    scaffoldKeyLoginPage.currentState.hideCurrentSnackBar();
                    if(user.isEmailVerified){
                      setState(() {
                        state=STATE_USER;
                      });
                    }
                    else{
                      signOut().then((_){
                        Fluttertoast.showToast(msg: 'EMAIL ID NOT VERIFIED');
                      });
                    }
                  }).catchError((error){
                    scaffoldKeyLoginPage.currentState.hideCurrentSnackBar();
                    Fluttertoast.showToast(msg: error.code.toString().replaceAll(RegExp('_'),' '));
                  });
                }
              },
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FlatButton(
                  splashColor: Colors.white,
                  child:Text(
                    'Sign Up',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.lightBlue
                    ),
                  ),
                  color: Colors.white.withOpacity(0.0),
                  padding: EdgeInsets.all(5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: (){
                    setState(() {
                      state=STATE_SIGN_UP;
                    });
                  },
                ),
                FlatButton(
                  splashColor: Colors.white,
                  child:Text(
                    'Forgot Password',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.lightBlue
                    ),
                  ),
                  color: Colors.white.withOpacity(0.0),
                  padding: EdgeInsets.all(5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: (){
                    setState(() {
                      state=STATE_FORGOT_PASSWORD;
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget getSignUpPage(){
    final cropKey = GlobalKey<CropState>();
    final emailController = new TextEditingController();
    final userNameController = new TextEditingController();
    final passwordController = new TextEditingController();
    final confirmPasswordController = new TextEditingController();
    // ignore: close_sinks
    StreamController<File> picStreamController = new StreamController<File>();
    Stream<File> picStream = picStreamController.stream;
    File sampledUploadImage;
    return Scaffold(
      key: scaffoldKeySignUpPage,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar:AppBar(
        title: Center(
            child:Text('Sign Up'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage('assets/images/login_background.jpg'),
            )
        ),
        padding: EdgeInsets.fromLTRB(40,20,40,10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              textInputAction: TextInputAction.none,
              controller: userNameController,
              decoration: InputDecoration(
                labelText: 'Username',
                helperText: '5-15 Alphanumeric Characters',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: EdgeInsets.fromLTRB(20,10,20,10),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            TextField(
              textInputAction: TextInputAction.none,
              controller: emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                labelText: 'Email',
                contentPadding: EdgeInsets.fromLTRB(20,10,20,10),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
              textInputAction: TextInputAction.none,
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                labelText: 'Password',
                contentPadding: EdgeInsets.fromLTRB(20,10,20,10),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
              textInputAction: TextInputAction.none,
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                labelText: 'Confirm Password',
                contentPadding: EdgeInsets.fromLTRB(20,10,20,10),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: ()async{
                    File originalImage = new File((await getImage()).path);
                    showDialog(
                      context:context,
                      builder: (BuildContext context){
                        return AlertDialog(
                          contentPadding: EdgeInsets.all(5),
                          content: Container(
                            height: 400,
                            child: Crop(
                              key:cropKey,
                              image: FileImage(originalImage),
                              aspectRatio: 1.0,
                            ),
                          ),
                          actions: <Widget>[
                            Row(
                              children: <Widget>[
                                FlatButton(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color: Colors.lightBlueAccent,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                FlatButton(
                                  child: Text(
                                    'Upload',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color: Colors.lightBlueAccent,
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    File croppedImage = await ImageCrop.cropImage(
                                      file: originalImage,
                                      scale: cropKey.currentState.scale,
                                      area: cropKey.currentState.area,
                                    );
                                    sampledUploadImage = await getSampledImage(croppedImage);
                                    picStreamController.add(sampledUploadImage);
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    );
                  },
                  child: StreamBuilder(
                    stream: picStream,
                    builder: (BuildContext context,AsyncSnapshot fileSnapshot){
                      if(fileSnapshot.hasData){
                        return Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.fill,
                                image: FileImage(fileSnapshot.data),
                              )
                          ),
                        );
                      }
                      else{
                        return Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.fill,
                                image: AssetImage('assets/images/user.jpg'),
                              ),
                          ),
                        );
                      }
                    },
                  )
                ),
                FlatButton(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.lightBlueAccent,
                  onPressed: ()async{
                    String userName = userNameController.text.trim();
                    String email = emailController.text.trim().toLowerCase();
                    String password = passwordController.text;
                    String confirmPassword = confirmPasswordController.text;
                    if(sampledUploadImage==null){
                      Fluttertoast.showToast(msg: 'ERROR PROFILE PIC NOT SELECTED');
                    }
                    else if(userName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty){
                      Fluttertoast.showToast(msg: 'ERROR ONE OR MORE FIELDS EMPTY');
                    }
                    else if(password!=confirmPassword){
                      Fluttertoast.showToast(msg: 'ERROR PASSWORDS DO NOT MATCH');
                    }
                    else if(validateUserName(userName)==false){
                      Fluttertoast.showToast(msg: 'ERROR INVALID USERNAME');
                    }
                    else{
                      showSnackBar(scaffoldKeySignUpPage,'Processing...');
                      Firestore.instance.collection('msging').document('users').collection(userName).limit(1).getDocuments().then((snapShot){
                        if(snapShot.documents.length!=0){
                          scaffoldKeySignUpPage.currentState.hideCurrentSnackBar();
                          Fluttertoast.showToast(msg: 'ERROR USERNAME ALREADY EXISTS');
                        }
                        else{
                          signUp(email, password).then((FirebaseUser user)async{
                            UserUpdateInfo userUpdateInfo = UserUpdateInfo();
                            userUpdateInfo.displayName=userName;
                            StorageTaskSnapshot snapShot = await FirebaseStorage.instance.ref().child(userName).putFile(sampledUploadImage).onComplete;
                            userUpdateInfo.photoUrl=await snapShot.ref.getDownloadURL();
                            user.updateProfile(userUpdateInfo).then((_)async{
                              await user.sendEmailVerification();
                              CollectionReference colRef=Firestore.instance.collection('msging').document('users').collection(userName);
                              signOut().then((_)async{
                                await colRef.document('friendList').setData({});
                                await colRef.document('reqList').setData({});
                                await colRef.document('messages').setData({});
                                await colRef.document('info').setData({
                                  'email':user.email,
                                  'uid':user.uid,
                                });
                                scaffoldKeySignUpPage.currentState.hideCurrentSnackBar();
                                Fluttertoast.showToast(msg:'VERIFICATION LINK SENT TO EMAIL');
                                setState(() {
                                  state=STATE_LOGIN;
                                });
                              });
                            }).catchError((error){
                              scaffoldKeySignUpPage.currentState.hideCurrentSnackBar();
                              Fluttertoast.showToast(msg: error.code.toString().replaceAll(RegExp('_'),' '));
                            });
                          }).catchError((error){
                            scaffoldKeySignUpPage.currentState.hideCurrentSnackBar();
                            Fluttertoast.showToast(msg: error.code.toString().replaceAll(RegExp('_'),' '));
                          });
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            FlatButton(
              splashColor: Colors.white,
              child:Text(
                'Go Back To Login Page',
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.lightBlue
                ),
              ),
              color: Colors.white.withOpacity(0.0),
              padding: EdgeInsets.all(5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: (){
                setState(() {
                  state=STATE_LOGIN;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget getForgotPasswordPage(){
    final emailController = new TextEditingController();
    return Scaffold(
      key: scaffoldKeyForgotPasswordPage,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar:AppBar(
        title: Text('Reset Password'),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage('assets/images/login_background.jpg'),
            )
        ),
        padding: EdgeInsets.fromLTRB(40,20,40,20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Image(
              height: 90,
              width: 90,
              image: AssetImage('assets/images/password_reset.png'),
            ),
            SizedBox(
              height: 30,
            ),
            TextField(
              textInputAction: TextInputAction.none,
              controller: emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                hintText: 'Email',
              ),
            ),
            SizedBox(
              height: 20,
            ),
            FlatButton(
              child: Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.lightBlueAccent,
              onPressed: (){
                FocusScope.of(context).requestFocus(new FocusNode());
                String email = emailController.text.trim().toLowerCase();
                if(email.isEmpty){
                  Fluttertoast.showToast(msg: 'ENTER EMAIL ID');
                }
                else{
                  showSnackBar(scaffoldKeyForgotPasswordPage,'Processing...');
                  resetPassword(email).then((_){
                    scaffoldKeyForgotPasswordPage.currentState.hideCurrentSnackBar();
                    Fluttertoast.showToast(msg: 'PASSWORD RESET LINK SENT TO EMAIL');
                    setState(() {
                      state=STATE_LOGIN;
                    });
                  }).catchError((error){
                    scaffoldKeyForgotPasswordPage.currentState.hideCurrentSnackBar();
                    Fluttertoast.showToast(msg: error.code.toString().replaceAll(RegExp('_'),' '));
                  });
                }
              },
            ),
            SizedBox(
              height: 20,
            ),
            FlatButton(
              splashColor: Colors.white,
              child:Text(
                'Go Back To Login Page',
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.lightBlue
                ),
              ),
              color: Colors.white.withOpacity(0.0),
              padding: EdgeInsets.all(5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: (){
                setState(() {
                  state=STATE_LOGIN;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget getUserPage(FirebaseUser user){
    return Scaffold(
      key: scaffoldKeyUserHomePage,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar:AppBar(
        title: Center(
          child:Text('@'+user.displayName),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            title: Text('Friends'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            title: Text('Requests'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_back),
            title: Text('LogOut'),
          ),
        ],
        currentIndex: userState,
        selectedItemColor: Colors.blue,
        onTap: (int index){
            if(index!=userState){
              if(index==USER_STATE_HOME){
                setState(() {
                  userState=USER_STATE_HOME;
                });
              }
              else if(index==USER_STATE_FRIENDS){
                setState(() {
                  userState=USER_STATE_FRIENDS;
                });
              }
              else if(index==USER_STATE_REQUESTS){
                setState(() {
                  userState=USER_STATE_REQUESTS;
                });
              }
              else if(index==USER_STATE_LOGOUT){
                showSnackBar(scaffoldKeyUserHomePage,'Loggin Out...');
                signOut().then((_){
                  scaffoldKeyUserHomePage.currentState.hideCurrentSnackBar();
                  setState(() {
                    userState=USER_STATE_HOME;
                    state=STATE_LOGIN;

                  });
                }).catchError((error){
                  scaffoldKeyUserHomePage.currentState.hideCurrentSnackBar();
                  Fluttertoast.showToast(msg: error.code.toString().replaceAll(RegExp('_'),' '));
                });
              }
            }
        },
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage('assets/images/background.jpg'),
            )
        ),
        child:getUserPageAsPerState(user),
      )
    );
  }

  Widget getUserPageAsPerState(FirebaseUser user){
    if(userState==USER_STATE_FRIENDS){
      return getUserFriendPage(user);
    }
    else if(userState==USER_STATE_REQUESTS){
      return getUserRequestPage(user);
    }
    else{
      return getUserHomePage(user);
    }
  }

  Widget getUserHomePage(FirebaseUser user){
    return Container(
      padding: EdgeInsets.fromLTRB(10,20,10,20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image:user.photoUrl==null?AssetImage('assets/images/user.jpg'):NetworkImage(user.photoUrl),
                  )
                ),
              ),
              SizedBox(
                width: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '@'+user.displayName,
                    style: TextStyle(
                        fontSize: 25
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    formatEmail(user.email),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15
                    ),
                  )
                ],
              )
            ],
          ),
          SizedBox(
            height: 15,
          ),
          StreamBuilder(
            stream: Firestore.instance.collection('msging').document('users').collection(user.displayName).snapshots(),
            builder: (BuildContext context,AsyncSnapshot colSnapshot){
              if(colSnapshot.hasData){
                Map chatList=colSnapshot.data.documents[2].data;
                return chatList.length==0?getCard(<Widget>[Text('No Messages Yet', style: TextStyle(fontSize: 15))], () {}):Expanded(
                  child: ListView.builder(
                    itemCount: chatList.length,
                    itemBuilder:(BuildContext context,int index){
                      DateTime date = DateTime.fromMillisecondsSinceEpoch(chatList.values.elementAt(index)['timestamp']);
                      return getCard(<Widget>[
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.fill,
                                image: NetworkImage(getUrl(chatList.keys.elementAt(index))),
                              )
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '@' + chatList.keys.elementAt(index),
                              style: TextStyle(
                                  fontSize: 18
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              msgFormat(chatList.values.elementAt(index)['message']),
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              (date.hour.toString().length==1?'0'+date.hour.toString():date.hour.toString())+':'+(date.minute.toString().length==1?'0'+date.minute.toString():date.minute.toString()),
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],(){
                        openChatPage(user,chatList.keys.elementAt(index),context);
                      });
                    },
                  ),
                );
              }
              else{
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget getUserFriendPage(FirebaseUser user){
    return Container(
        padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 0,
                width: double.infinity,
              ),
              Text(
                'Friend List ',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.blue,
                ),
              ),
              SizedBox(
                height: 15,
              ),
              StreamBuilder(
                  stream: Firestore.instance.collection('msging').document('users').collection(user.displayName).snapshots(),
                  builder: (BuildContext context, AsyncSnapshot colSnapshot) {
                    if (colSnapshot.hasData) {
                      Map friendList = colSnapshot.data.documents[0].data;
                      return friendList.length == 0 ? getCard(<Widget>[Text('No Friends Yet', style: TextStyle(fontSize: 15))], () {}) : Expanded(
                        child: ListView.builder(
                          itemCount: friendList.length,
                          itemBuilder: (context, index) {
                            return getCard(<Widget>[
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      fit: BoxFit.fill,
                                      image: NetworkImage(getUrl(friendList.keys.elementAt(index))),
                                    )
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '@' + friendList.keys.elementAt(index),
                                    style: TextStyle(
                                        fontSize: 18
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    formatEmail(friendList.values.elementAt(index)),
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  )
                                ],
                              ),
                            ], () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return SimpleDialog(
                                      title: Text(
                                        '@' + friendList.keys.elementAt(index),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.blue,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.all(20),
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            FlatButton(
                                              child: Text(
                                                'Message',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              color: Colors.lightBlueAccent,
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                openChatPage(user,friendList.keys.elementAt(index),context);
                                              },
                                            ),
                                            FlatButton(
                                              child: Text(
                                                'Unfriend',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              color: Colors.lightBlueAccent,
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                await Firestore.instance.collection('msging').document('users').collection(user.displayName).document('friendList').updateData({
                                                  friendList.keys.elementAt(index): FieldValue.delete(),
                                                });
                                                await Firestore.instance.collection('msging').document('users').collection(
                                                    friendList.keys.elementAt(index)).document('friendList').updateData({
                                                  user.displayName: FieldValue.delete(),
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      ],
                                    );
                                  });
                            });
                          },
                        ),
                      );
                    }
                    else {
                      return Container();
                    }
                  }
              )
            ]
        )
    );
  }

  Widget getUserRequestPage(FirebaseUser user){
    return Container(
      padding: EdgeInsets.fromLTRB(10,20,10,20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 0,
            width: double.infinity,
          ),
          getCard(<Widget>[
            SizedBox(
              height: 50,
              width: 50,
              child: Icon(
                Icons.add_circle,
                color: Colors.blue,
                size: 50,
              ),
            ),
            SizedBox(
              width: 20,
            ),
            Text(
              'Add New Friend',
            )
          ],(){
            final TextEditingController friendRequestUserNameController= new TextEditingController();
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  // ignore: close_sinks
                  StreamController<String> titleController = StreamController<String>.broadcast();
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: EdgeInsets.all(20),
                    title: StreamBuilder(
                        stream: titleController.stream,
                        builder: (BuildContext context, AsyncSnapshot<String> snapshot){
                          return Text(
                            snapshot.hasData ? snapshot.data : 'Add New Friend',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          );
                        }),
                    content: TextField(
                      controller:friendRequestUserNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        hintText: 'Enter Username',
                      ),
                    ),
                    actions: [
                      FlatButton(
                        onPressed: () {
                          FocusScope.of(context).requestFocus(new FocusNode());
                          if(friendRequestUserNameController.text.trim().isEmpty){
                            Fluttertoast.showToast(msg: 'ERROR USERNAME FIELD EMPTY');
                          }
                          else if(friendRequestUserNameController.text.trim()==user.displayName){
                            friendRequestUserNameController.clear();
                            Fluttertoast.showToast(msg: 'ERROR CANT SEND FRIEND REQUEST TO SELF');
                          }
                          else{
                            titleController.add('Loading...');
                            Firestore.instance.collection('msging').document('users').collection(friendRequestUserNameController.text.trim()).limit(1).getDocuments().then((snapShot){
                              if(snapShot.documents.length!=0){
                                Firestore.instance.collection('msging').document('users').collection(user.displayName).document('friendList').get().then((docSnapshot) async{
                                  if(docSnapshot.data.containsKey(friendRequestUserNameController.text.trim())){
                                    friendRequestUserNameController.clear();
                                    titleController.add('Add New Friend');
                                    Fluttertoast.showToast(msg: 'ERROR USER ALREADY IN FRIEND LIST');
                                  }
                                  else {
                                    await Firestore.instance.collection('msging').document('users').collection(friendRequestUserNameController.text.trim()).document('reqList').updateData({
                                      user.displayName:user.email,
                                    });
                                    Navigator.of(context).pop();
                                    Fluttertoast.showToast(msg: 'FRIEND REQUEST SENT SUCCESSFULLY');
                                  }
                                });
                              }
                              else{
                                titleController.add('Add New Friend');
                                friendRequestUserNameController.clear();
                                Fluttertoast.showToast(msg: 'ERROR USERNAME NOT FOUND');
                              }
                            });
                          }
                        },
                        child: Text(
                          'Send request',
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15
                          ),
                        ),
                      ),
                    ],
                  );
                });
          }),
          SizedBox(
            height: 15,
          ),
          Text(
            'Pending Requests ',
            style: TextStyle(
              fontSize: 30,
              color: Colors.blue,
            ),
          ),
          SizedBox(
            height: 15,
          ),
          StreamBuilder(
            stream: Firestore.instance.collection('msging').document('users').collection(user.displayName).snapshots(),
            builder: (BuildContext context,AsyncSnapshot colSnapshot) {
              if(colSnapshot.hasData){
                Map reqList = colSnapshot.data.documents[3].data;
                return reqList.length==0?getCard(<Widget>[Text('No Friend Requests Pending',style: TextStyle(fontSize: 15))],(){}):Expanded(
                  child: ListView.builder(
                    itemCount: reqList.length,
                    itemBuilder: (context,index) {
                      return getCard(<Widget>[
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.fill,
                                image:NetworkImage(getUrl(reqList.keys.elementAt(index))),
                              )
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '@'+reqList.keys.elementAt(index),
                              style: TextStyle(
                                  fontSize: 18
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              formatEmail(reqList.values.elementAt(index)),
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            )
                          ],
                        )
                      ],(){
                        showDialog(
                            context: context,
                            builder: (BuildContext context){
                              return SimpleDialog(
                                title: Text(
                                  'Accept Friend Request ?',
                                  style: TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                                contentPadding: EdgeInsets.all(20),
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: FloatingActionButton(
                                          child: Icon(
                                            Icons.close,
                                            size: 30,
                                          ),
                                          onPressed: () async{
                                            Navigator.of(context).pop();
                                            await Firestore.instance.collection('msging').document('users').collection(user.displayName).document('reqList').updateData({
                                              reqList.keys.elementAt(index):FieldValue.delete(),
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: FloatingActionButton(
                                          child: Icon(
                                            Icons.done,
                                            size: 30,
                                          ),
                                          onPressed: (){
                                            Navigator.of(context).pop();
                                            Firestore.instance.collection('msging').document('users').collection(user.displayName).document('reqList').updateData({
                                              reqList.keys.elementAt(index):FieldValue.delete(),
                                            });
                                            Firestore.instance.collection('msging').document('users').collection(user.displayName).document('friendList').updateData({
                                              reqList.keys.elementAt(index):reqList.values.elementAt(index),
                                            });
                                            Firestore.instance.collection('msging').document('users').collection(reqList.keys.elementAt(index)).document('friendList').updateData({
                                              user.displayName:user.email,
                                            });
                                            Firestore.instance.collection('msging').document('users').collection(reqList.keys.elementAt(index)).document('reqList').updateData({
                                              user.displayName:FieldValue.delete(),
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            });
                      });
                    },
                  ),
                );
              }
              else{
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget getLoadingPage(){
    return Scaffold(
      body: Center(
        child: Text(
          'Loading . . . ',
          style: TextStyle(
            fontSize: 25,
          ),
        ),
      ),
    );
  }
}

GestureDetector getCard(List <Widget> childrenWidgets,tapFunction){
  return GestureDetector(
    onTap: tapFunction,
    child: Card(
      child: Padding(
          padding:EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: childrenWidgets,
          )
      ),
    ),
  );
}

void showSnackBar(GlobalKey<ScaffoldState> scaffoldKey,String snackBarText){
  scaffoldKey.currentState.showSnackBar(SnackBar(
      duration: Duration(days: 1),
      backgroundColor: Colors.black.withOpacity(0.2),
      content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_){},
          child: SizedBox.expand(
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: 80,
                          width: 80,
                          child: CircularProgressIndicator(),
                        ),
                        SizedBox(
                          height: 90,
                        ),
                        Text(
                            snackBarText,
                            style: TextStyle(
                              fontSize: 20,
                            )
                        )
                      ]
                  )
              )
          )
      )
  ));
}

void openChatPage(FirebaseUser user,String username,BuildContext context){
  TextEditingController msgController = new TextEditingController();
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context){
        return SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: AssetImage('assets/images/chat_background.jpg'),
                )
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: true,
              appBar: PreferredSize(
                  preferredSize: Size.fromHeight(65),
                  child: Container(
                    color: Colors.blue,
                    child: Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 20,
                          ),
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image:NetworkImage(getUrl(username)),
                                )
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            '@'+username,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                      child: StreamBuilder(
                        stream: Firestore.instance.collection('msging').document('users').collection(user.displayName).document('messages').collection(username).orderBy('timestamp').snapshots(),
                        builder: (BuildContext context,AsyncSnapshot colSnapshot){
                          if(colSnapshot.hasData){
                            List <DocumentSnapshot> chats = List.from(colSnapshot.data.documents.reversed);
                            return ListView.builder(
                              itemCount: chats.length,
                              reverse: true,
                              itemBuilder: (BuildContext context,int index){
                                return getChat(chats[index]['message'],chats[index]['timestamp'],chats[index]['sender']!=user.displayName,(){});
                              },
                            );
                          }
                          else{
                            return Container();
                          }
                        },
                      )
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: TextField(
                            controller: msgController,
                            textInputAction: TextInputAction.none,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              labelText: 'Enter Message',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        FloatingActionButton(
                          child: Icon(
                            Icons.send,
                            size: 40,
                          ),
                          onPressed: ()async{
                            String msg=msgController.text.trim();
                            if(msg.isNotEmpty){
                              msgController.clear();
                              FocusScope.of(context).requestFocus(new FocusNode());
                              Firestore.instance.collection('msging').document('users').collection(user.displayName).document('messages').collection(username).document().setData({
                                'message':msg,
                                'sender':user.displayName,
                                'timestamp':DateTime.now().millisecondsSinceEpoch,
                              });
                              Firestore.instance.collection('msging').document('users').collection(username).document('messages').collection(user.displayName).document().setData({
                                'message':msg,
                                'sender':user.displayName,
                                'timestamp':DateTime.now().millisecondsSinceEpoch,
                              });
                              Firestore.instance.collection('msging').document('users').collection(user.displayName).document('messages').updateData({
                                username:{
                                  'message':msg,
                                  'sender':user.displayName,
                                  'timestamp':DateTime.now().millisecondsSinceEpoch,
                                }
                              });
                              Firestore.instance.collection('msging').document('users').collection(username).document('messages').updateData({
                                user.displayName:{
                                  'message':msg,
                                  'sender':user.displayName,
                                  'timestamp':DateTime.now().millisecondsSinceEpoch,
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
  );
}

bool validateUserName(String username){
  final  RegExp validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
  if(username.length>=5 && username.length<=15 && validCharacters.hasMatch(username)){
    return true;
  }
  else{
    return false;
  }
}

String formatEmail(String email){
  if(email.length>30){
    email=email.substring(0,30)+'...';
  }
  return email;
}

String msgFormat(String msg){
  if(msg.length>25){
    return msg.substring(0,25)+'....';
  }
 return msg;
}

Widget getChat(String text,int time,bool key,tapFunction){
  DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
  return GestureDetector(
    onTap: tapFunction,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10,8,10,8),
        child: Wrap(
          alignment: key?WrapAlignment.start:WrapAlignment.end,
          children: <Widget>[
            Bubble(
              margin: key?BubbleEdges.only(right: 35):BubbleEdges.only(left: 35),
              nip: key?BubbleNip.leftTop:BubbleNip.rightTop,
              color: key?Colors.white:Colors.lightBlueAccent.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 18,
                      color:Colors.black,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    (date.hour.toString().length==1?'0'+date.hour.toString():date.hour.toString())+':'+(date.minute.toString().length==1?'0'+date.minute.toString():date.minute.toString()),
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              )
            ),
          ],
        ),
      ),
  );
}
Future getImage() async {
  return await ImagePicker().getImage(source: ImageSource.gallery);
}

Future getSampledImage(File image) async{
  return await ImageCrop.sampleImage(
    file: image,
    preferredWidth: 150,
    preferredHeight: 150,
  );
}

String getUrl(String userName){
  return 'https://firebasestorage.googleapis.com/v0/b/msging-fe522.appspot.com/o/'+userName+'?alt=media';
}

Future<FirebaseUser> signUp(String email,String password) async {
  AuthResult result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  final FirebaseUser user = result.user;
  assert (user != null);
  assert (await user.getIdToken() != null);
  return user;
}

Future<FirebaseUser> signIn(String email,String password) async {
  AuthResult result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  final FirebaseUser user = result.user;
  assert (user != null);
  assert (await user.getIdToken() != null);
  return user;
}

Future<FirebaseUser> getUser() async{
  FirebaseUser user = await FirebaseAuth.instance.currentUser();
  assert (user != null);
  assert (await user.getIdToken() != null);
  return user;
}

Future<void> resetPassword(String email) async{
  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
}

Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
}