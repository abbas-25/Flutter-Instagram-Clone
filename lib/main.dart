import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import './pages/home.dart';

void main() {
  runApp(MyApp());
  Firestore.instance
      .settings(timestampsInSnapshotsEnabled: true)
      .then((_) {}, onError: (_) {});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlipClip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        accentColor: Colors.white,
      ),
      home: Home(),
    );
  }
}
