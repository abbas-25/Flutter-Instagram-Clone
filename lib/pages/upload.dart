import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import './home.dart';
import '../widgets/progress.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload>{
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File imageFile;
  bool _isUploading = false;
  String postId = Uuid().v4();

  _handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      imageFile = file;
    });
  }

  _handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      imageFile = file;
    });
  }

  _selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('Create Post'),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Photo with Camera"),
                onPressed: _handleTakePhoto,
              ),
              SimpleDialogOption(
                child: Text("Photo from Gallery"),
                onPressed: _handleChooseFromGallery,
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  Container _buildSplashScreen() {
    return Container(
      // color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 260,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              onPressed: () => _selectImage(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Upload Image',
                style: GoogleFonts.bitter(
                  textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                ),
                ),
              ),
              color: Colors.blue,
            ),
          )
        ],
      ),
    );
  }

  _clearImage() {
    setState(() {
      imageFile = null;
    });
  }

  _compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageF =
        Im.decodeImage(imageFile.readAsBytesSync()); //reading the image file

    //create path and write to that path, result will be the compressed file
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageF, quality: 85));
    setState(() {
      imageFile = compressedImageFile;
    });
  }

  Future _uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  _handleSubmit() async {
    setState(() {
      _isUploading = true;
    });
    await _compressImage();
    String mediaUrl = await _uploadImage(imageFile);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      caption: captionController.text,
      location: locationController.text,
    );
  }

  createPostInFirestore({String mediaUrl, String caption, String location}) {
    postsRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "location": location,
      "timestamp": timestamp,
      "description": caption,
      "likes": {}
    });
    captionController.clear();
    locationController.clear();
    setState(() {
      imageFile = null;
      _isUploading = false;
      postId = Uuid()
          .v4(); //setting postId to a new unique id so it doesn't remain same for the next posts
    });
  }

  Scaffold _buildUpload(mQuery) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white70,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black54,
            ),
            onPressed: _clearImage,
          ),
          title: Text(
            "Edit Post",
            style: TextStyle(color: Colors.black54),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: _isUploading ? null : () => _handleSubmit(),
              child: Icon(
                Icons.check,
                size: 36.0,
                color: Colors.black87
              ) 
              // Text(
              //   "Post",
              //   style: TextStyle(
              //     color: Theme.of(context).primaryColor,
              //     fontWeight: FontWeight.bold,
              //     fontSize: 20.0,
              //   ),
              // ),
            )
          ],
        ),
        body: ListView(
          children: <Widget>[
            _isUploading ? linearProgress(context) : Text(""),
            Container(
              height: mQuery.size.height * 0.35,
              width: mQuery.size.width * 0.8,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                      fit: BoxFit.contain,
                      image: FileImage(imageFile),
                    )),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10.0),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    CachedNetworkImageProvider((widget.currentUser.photoUrl)),
              ),
              title: Container(
                width: mQuery.size.width * 0.7,
                child: TextField(
                  controller: captionController,
                  decoration: InputDecoration(
                    hintText: "Write a caption..",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.pin_drop,
                color: Colors.orange,
                size: 35.0,
              ),
              title: Container(
                width: mQuery.size.width * 0.7,
                child: TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    hintText: "Add current location",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Container(
              width: mQuery.size.width * 0.65,
              height: mQuery.size.height * 0.1,
              alignment: Alignment.center,
              child: RaisedButton.icon(
                label: Text(
                  "Use Current Location",
                  style: TextStyle(color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                color: Colors.red,
                onPressed: _getUserLocation,
                icon: Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ));
  }

  _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String formattedAddress = '${placemark.locality}, ${placemark.country}';
    
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var mQuery = MediaQuery.of(context);
    return imageFile == null ? _buildSplashScreen() : _buildUpload(mQuery);
  }
}
