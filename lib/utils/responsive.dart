import 'package:flutter/cupertino.dart';

bool isMobile (BuildContext context) {
  if(MediaQuery.of(context).size.width < 500) return true;
  return false;
}