import 'package:csolve/components/home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'crossword_model.dart';
//TODO need to change something in android manifest file?

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossword',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text('CSolve'),
        ),
        body: Center(
          child: HomePage(),
        ),
      ),
    );
  }
}
