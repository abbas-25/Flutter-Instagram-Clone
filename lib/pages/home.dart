import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import './create_account.dart';
import '../models/user.dart';
import '../pages/activity_feed.dart';
import '../pages/profile.dart';
import '../pages/search.dart';
import '../pages/timeline.dart';
import '../pages/upload.dart';

final GoogleSignIn googleSignIn = new GoogleSignIn();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final StorageReference storageRef = FirebaseStorage.instance.ref();
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _isAuth = false;
  PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    googleSignIn.onCurrentUserChanged.listen((account) {
      _handleSignIn(account);
    }, onError: (e) {
      print('error -- ${e.toString()}');
    });

    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      _handleSignIn(account);
    }).catchError((err) {
      print('${err.toString()}');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await _createUserInFirestore();
      setState(() {
        _isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        _isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    
    _firebaseMessaging.getToken().then( (token) {
     
      usersRef.document(user.id).updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
     
      onMessage: (Map<String, dynamic> message) async {
        
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if(recipientId == user.id) {
       
          SnackBar snackBar = SnackBar(content: Text(body, overflow: TextOverflow.ellipsis,),);
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
        
      },
    );
  }

  Future _createUserInFirestore() async {
    //check if user exists in users collection in db (using id)
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot userDoc = await usersRef.document(user.id).get();

    //if it doesn't exist, take them to create account page
    if (!userDoc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      // get username from createaccount an make a new user in firestore collection
      usersRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp,
        "searchHelper": (user.displayName).toLowerCase()
      });
      

      userDoc = await usersRef.document(user.id).get();
    }

    currentUser = User.fromDocument(userDoc);
   
  }

  void _login() async {
    try {
      await googleSignIn.signIn();
    } catch (e) {
      print('${e.toString()}');
    }
  }

  void _logout() {
    googleSignIn.signOut();
  }

  _onPageChanged(int pageIndex) {
    setState(() {
      this._pageIndex = pageIndex;
    });
  }

  _onTap(int pageIndex) {
    _pageController.animateToPage(pageIndex,
        curve: Curves.easeInOut, duration: Duration(milliseconds: 200));
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id)
        ],
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _pageIndex,
        onTap: _onTap,
        activeColor: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera, size: 35.0),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle,
            ),
          )
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      
      body: Container(
        
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover
          )
            // gradient: LinearGradient(
            //     begin: Alignment.topRight,
            //     end: Alignment.bottomRight,
            //     colors: [
            //   Theme.of(context).accentColor,
            //   Theme.of(context).primaryColor,
            // ])
            ),
       alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'FlipClip',
              style: GoogleFonts.bangers(
                  fontSize: 90, color: Colors.white, letterSpacing: 2.5),
            ),
            GestureDetector(
              onTap: _login,
              child: Container(
                width: 260.0,
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
