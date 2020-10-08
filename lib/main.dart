import 'package:csolve/crossword_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//TODO need to change something in android manifest file?

/// TODOS:
/// Text Entry callback to update site
/// Text Entry to only have one letter (use Controller?)
/// Prettify Text Entry
/// Add Down clues
/// fix overflow when keyboard pops up - don't care about this, so how to basically
///    ignore or say "just fill whatever"? Little suprised it doesn't work already.
///    Maybe ask Keith.

/////// Widget building
// Build grid
// todo move to seaparte build file
// void main() => runApp(ChangeNotifierProvider(
//       create: (context) => GridModel(),
//       child: MyApp(),
//     ));
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
