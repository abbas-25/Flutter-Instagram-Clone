import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../models/user.dart';
import './activity_feed.dart';
import './home.dart';
import '../widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController _searchController = TextEditingController();
  Future<QuerySnapshot> _searchResultsFuture;

  _handleSearch(String query) {
   
    Future<QuerySnapshot> users = usersRef
        .where('searchHelper', isGreaterThanOrEqualTo: query)
        .getDocuments();
    

    setState(() {
      _searchResultsFuture = users;
    });
  }

  _clearSearch() {
    _searchController.clear();
  }

  AppBar _buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
            hintText: "Search for users..",
            filled: true,
            prefixIcon: Icon(
              Icons.account_box,
              size: 28.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearSearch,
            )),
        onFieldSubmitted: _handleSearch,
      ),
    );
  }

  Container _buildNoContent(screenSize) {
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: screenSize.height * 0.8,
            ),
          ],
        ),
      ),
    );
  }

  _buildSearchResults() {
    
    return FutureBuilder(
      future: _searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }
        List<UserResult> searchResults = [];

        
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);

          searchResults.add(UserResult(user));
        });
        
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mQuery = MediaQuery.of(context);
    return Scaffold(
        appBar: _buildSearchField(),
        body: _searchResultsFuture == null
            ? _buildNoContent(mQuery.size)
            : _buildSearchResults());
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      //color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          )
        ],
      ),
    );
  }
}
