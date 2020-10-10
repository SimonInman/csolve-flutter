import 'package:csolve/crossword_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//TODO need to change something in android manifest file?

/// TODOS:
/// Prettify Text Entry
/// Add Down clues
/// fix overflow when keyboard pops up - don't care about this, so how to basically
///    ignore or say "just fill whatever"? Little suprised it doesn't work already.
///    Maybe ask Keith.

/////// Widget building
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossword Width',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text('here is a second title?'),
        ),
        body: Center(
          child: CrosswordLoader(),
        ),
      ),
    );
  }
}
