import 'package:flutter/material.dart';
import 'package:hydrate/view/info_product_view.dart';
import 'package:hydrate/view/screen/home_screen.dart';
import 'package:hydrate/view/screen/home_screen1.dart';
import 'package:hydrate/view/screen/modal_coba.dart';
import 'package:hydrate/view/screen/profile_screen.dart';
void main(List<String> args) {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYDRATE',
      theme: ThemeData(),
      debugShowCheckedModeBanner: false,
      home: InfoProduct(),
      // home:  HydrationPicker(),\
    );
  }
}
