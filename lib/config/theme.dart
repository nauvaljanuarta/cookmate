import 'package:flutter/cupertino.dart';

class AppTheme {

  static const Color primaryColor = CupertinoColors.activeOrange;
  static const Color secondaryColor = CupertinoColors.systemYellow;
  static const Color backgroundColor = CupertinoColors.systemBackground;
  static const Color textColor = CupertinoColors.darkBackgroundGray;
  static const Color accentColor = CupertinoColors.activeGreen;

  static const TextStyle headingStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.bold,
    fontSize: 22,
    color: textColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: textColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 16,
    color: textColor,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    color: CupertinoColors.systemGrey,
  );
  // ini style cupertino
  static final CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    primaryColor: primaryColor,
    barBackgroundColor: CupertinoColors.systemBackground,
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    textTheme: CupertinoTextThemeData(
      navTitleTextStyle: const TextStyle(
        fontFamily: 'Montserrat',
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      navLargeTitleTextStyle: const TextStyle(
        fontFamily: 'Montserrat',
        color: textColor,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
      navActionTextStyle: const TextStyle(
        fontFamily: 'Montserrat',
        color: primaryColor,
        fontSize: 16,
      ),
      textStyle: const TextStyle(
        fontFamily: 'Montserrat',
        color: textColor,
        fontSize: 16,
      ),
      tabLabelTextStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 12,
      ),
      actionTextStyle: const TextStyle(
        fontFamily: 'Montserrat',
        color: primaryColor,
        fontSize: 16,
      ),
      pickerTextStyle: const TextStyle(
        fontFamily: 'Montserrat',
        color: textColor,
        fontSize: 16,
      ),
      dateTimePickerTextStyle: const TextStyle(
        fontFamily: 'Montserrat',
        color: textColor,
        fontSize: 16,
      ),
    ),
  );

  static const double cardHeight = 240;
  static const double cardWidthRatio = 0.6; 
  static const double cardBorderRadius = 20.0;
  static const double spaceForShadow = 30.0;
}

