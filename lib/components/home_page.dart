import 'dart:async';

import 'package:csolve/crossword_model.dart';
import 'package:csolve/models/suggestion.dart';
import 'package:csolve/network/network.dart';
import 'package:flutter/material.dart';

const SOURCES = [
  'guardian-cryptic',
  'guardian-quiptic',
  'guardian-prize',
  'guardian-everyman',
  'independent',
  'independent-on-sunday',
  'nyt',
  'new-yorker',
  'private-eye',
];

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String crosswordPath = 'independent';
  String? crosswordId;
  // TODO this isn't actually used yet
  String solveGroup = 'the-everymen';

  Future<DropdownButton> buildButton() async {
    final list = await (fetchSuggestions(crosswordPath: crosswordPath)
        as FutureOr<List<Suggestion>>);
    final dropdownItems = list
        .map((suggestion) => new DropdownMenuItem(
              value: suggestion.id,
              child: new Text(suggestion.prettyPrint()),
            ))
        .toList();
    return DropdownButton<String>(
      hint: Text('Select a crossword...'),
      value: crosswordId,
      items: dropdownItems,
      onChanged: (String? newValue) {
        setState(() {
          crosswordId = newValue;
        });
      },
    );
  }

  Widget suggestionsList() {
    return FutureBuilder<DropdownButton>(
      future: buildButton(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dropdownItems = SOURCES
        .map((value) =>
            new DropdownMenuItem(value: value, child: new Text(value)))
        .toList();

    final sourceDropdown = DropdownButton<String>(
      value: crosswordPath,
      items: dropdownItems,
      style: TextStyle(color: Colors.deepPurple),
      onChanged: (String? newValue) {
        setState(() {
          crosswordPath = newValue!;
          crosswordId = null;
        });
      },
    );

    final idField = TextField(
        textAlign: TextAlign.center,
        onChanged: (value) {
          setState(() {
            crosswordId = value;
          });
        });

    final solveGroupField = TextField(
        textAlign: TextAlign.center,
        onChanged: (value) {
          setState(() {
            solveGroup = value;
          });
        });

    final button = RaisedButton(
      child: Text('Open route'),
      onPressed: () {
        // Navigate to second route when tapped.
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CrosswordScreen(
                    crosswordId: crosswordId!,
                    crosswordPath: crosswordPath,
                  )),
        );
      },
    );

    return Column(children: [
      Text(
        'Source',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      sourceDropdown,
      Text(
        'ID',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      suggestionsList(),
      // Text(
      //   'Solve Group',
      //   style: TextStyle(fontWeight: FontWeight.bold),
      // ),
      // solveGroupField,
      button,
    ]);
  }
}
