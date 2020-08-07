import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

header(context,
    {bool isAppTitle = false,
    String titleText,
    bool removeBackButton = false}) {
  return AppBar(
    iconTheme: IconThemeData(
      color: Colors.black87
    ),
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(isAppTitle ? 'FlipClip' : titleText,
        style: isAppTitle
            ? GoogleFonts.bangers(
                textStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 42.0,
                ),
                letterSpacing: 2.5)
            : GoogleFonts.bitter(
              textStyle:  TextStyle(
                color: Colors.black87,
                fontSize: 24,
                                
              ),
              
              ),
            ),

           
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
