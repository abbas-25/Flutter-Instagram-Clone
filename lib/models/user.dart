import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  final String searchHelper;

  User({
    this.displayName,
    this.photoUrl,
    this.id,
    this.username,
    this.bio,
    this.email,
    this.searchHelper
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      email: doc['email'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      searchHelper: doc['searchHelper']
    );
  }
}
