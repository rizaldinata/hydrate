import 'package:flutter/material.dart';
import 'package:hydrate/presentation/screens/info_product_view.dart';
// import 'package:hydrate/presentation/widgets/circular.dart';
// import 'package:hydrate/presentation/screens/coba_air.dart';
// // import 'package:hydrate/view/info_product_view.dart';
// import 'package:hydrate/presentation/screens/home_screen.dart';
// import 'package:hydrate/presentation/screens/home_screen1.dart';

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
    );
  }
}
