import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:google_fonts/google_fonts.dart';

import '../models/user.dart';
import './home.dart';
import '../widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  User user;
  TextEditingController _displayNameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  bool _isDisplayNameValid = true;
  bool _isBioValid = true;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  _getUser() async {
    setState(() {
      _isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    _displayNameController.text = user.displayName;
    _bioController.text = user.bio;
    setState(() {
      _isLoading = false;
    });
  }

  Column _buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            "Display Name",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: _displayNameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _isDisplayNameValid ? null : "Display Name too Short!" ),
        )
      ],
    );
  }

  Column _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            "Bio",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: _bioController,
          decoration: InputDecoration(hintText: "Update Bio",
          errorText: _isBioValid ? null : "Bio too long!" )),
        
      ],
    );
  }

  _updateProfileData() {
    setState(() {
      _displayNameController.text.trim().length < 3 ||
      _displayNameController.text.isEmpty 
      ? _isDisplayNameValid = false
      : _isDisplayNameValid = true;

      _bioController.text.trim().length > 100 
      ? _isBioValid = false 
      : _isBioValid = true;
    });

    if(_isDisplayNameValid && _isBioValid) {
      usersRef.document(widget.currentUserId).updateData(
        {
          "displayName": _displayNameController.text,
          "bio": _bioController.text,
        }
      );
      SnackBar snackBar = SnackBar(content: Text("Profile Updated!"),);
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  } 

  _logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Home()
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30,
              color: Theme.of(context).accentColor,
            ),
          )
        ],
      ),
      body: _isLoading
          ? circularProgress(context)
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 8),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage: CachedNetworkImageProvider(
                            user.photoUrl,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            _buildDisplayNameField(),
                            _buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        onPressed:_updateProfileData,
                        color: Colors.blue,
                        child: Text("Update Profile", style: GoogleFonts.bitter(
                          textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          
                        ),),
                        )
                        
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: RaisedButton.icon(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                          ),
                          onPressed: _logout,
                          icon: Icon(Icons.cancel, color: Theme.of(context).primaryColor,),
                          label: Text("LOGOUT", style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20.0
                          ),),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
