import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../pages/activity_feed.dart';
import '../pages/comments.dart';
import '../pages/home.dart';
import '../widgets/custom_image.dart';
import '../widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
        postId: doc['postId'],
        ownerId: doc['ownerId'],
        username: doc['username'],
        location: doc['location'],
        description: doc['description'],
        mediaUrl: doc['mediaUrl'],
        likes: doc['likes']);
  }

  int getLikeCount() {
    //if not likes
    if (likes == null) {
      return 0;
    }
    int count = 0;
    //if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool _isLiked;
  bool _showHeart = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  _buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey,
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
          ),
          title: GestureDetector(
            child: Text(
              '${user.displayName}',
              style:
                  TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
            ),
            onTap: () => showProfile(context, profileId: user.id),
          ),
          subtitle: Text('$location'),
          trailing: isPostOwner ? IconButton(
            onPressed: () => handleDeletePost(context),
            icon: Icon(Icons.more_vert) ,
          ) : Text('')
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove post?"),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).errorColor),
                ),
              ),
              SimpleDialogOption(
                child: Text(
                  'Cancel',
                  
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        });
  }

  // Note: to delete a post, ownerId and currentUserId must be equal
  // so they can be used interchangably
  deletePost() async {
    //delete the post itself

    postsRef.document(ownerId).collection('userPosts').document
    (postId).get().then( (doc) {
      if(doc.exists) {
        doc.reference.delete();
      }
    });

    //delete the uploaded image 
    storageRef.child("post_$postId.jpg").delete();

    //delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await  activityFeedRef.document(ownerId).collection("feedItems")
    .where('postId', isEqualTo: postId).getDocuments();

    activityFeedSnapshot.documents.forEach( (doc) {
      if(doc.exists) {
        doc.reference.delete();
      }
    });

    // delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef.document(postId).collection('comments')
    .getDocuments();

    commentsSnapshot.documents.forEach( (doc) {
      if(doc.exists) {
        doc.reference.delete();
      }
    });

    
  }

  _handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;
    if (_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      _removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        _isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});

      _addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        _isLiked = true;
        likes[currentUserId] = true;
        _showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          _showHeart = false;
        });
      });
    }
  }

  _removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  _addLikeToActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .setData({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "timestamp": timestamp,
        "mediaUrl": mediaUrl
      });
    }
  }

  _buildPostImage() {
    return GestureDetector(
      onDoubleTap: _handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          _showHeart
              ? Animator(
                  duration: Duration(milliseconds: 400),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.easeInToLinear,
                  cycles: 0,
                  builder: (anim) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text('')
        ],
      ),
    );
  }

  _showComments(
    BuildContext context, {
    String postId,
    String ownerId,
    String mediaUrl,
  }) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Comments(
                postId: postId, postOwnerId: ownerId, postMediaUrl: mediaUrl)));
  }

  _buildPostFooter() {
    return Column(children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 40, left: 20.0),
          ),
          GestureDetector(
            onTap: _handleLikePost,
            child: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              size: 28.0,
              color: Colors.pink,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 20.0),
          ),
          GestureDetector(
            onTap: () => _showComments(context,
                postId: postId, ownerId: ownerId, mediaUrl: mediaUrl),
            child: Icon(
              Icons.chat,
              size: 28.0,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
      Row(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 20.0),
            child: Text(
              "$likeCount likes",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 20.0),
            child: Text(
              "${username} ",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
                margin: EdgeInsets.only(right: 10), child: Text(description)),
          )
        ],
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildPostHeader(),
        _buildPostImage(),
        _buildPostFooter(),
      ],
    );
  }
}
