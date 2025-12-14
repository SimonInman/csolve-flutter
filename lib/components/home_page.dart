import 'dart:async';

import 'package:csolve/crossword_model.dart';
import 'package:csolve/models/suggestion.dart';
import 'package:csolve/network/network.dart';
import 'package:flutter/material.dart';

const DEFAULT_SOURCES = [
  'guardian-cryptic',
  'guardian-everyman',
  'guardian-gemolo',
  'guardian-prize',
  'guardian-quiptic',
  'guardian-quick',
  'guardian-speedy',
  'guardian-genius',
  'independent',
  'independent-on-sunday',
  'financial-times',
  'nyt',
  'new-yorker',
  'private-eye',
];

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> crosswordSources = DEFAULT_SOURCES;
  String crosswordPath = DEFAULT_SOURCES.first;
  String? crosswordId;
  // TODO this isn't actually used yet
  String solveGroup = 'the-everymen';

  @override
  void initState() {
    super.initState();
    _loadCrosswordSources();
  }

  Future<void> _loadCrosswordSources() async {
    final sources = await fetchSources();
    if (sources.isNotEmpty) {
      setState(() {
        crosswordSources = sources;
        if (!crosswordSources.contains(crosswordPath)) {
          crosswordPath = crosswordSources.first;
          crosswordId = null;
        }
      });
    }
  }

  Future<DropdownButton> buildButton() async {
    final list = await fetchSuggestions(crosswordPath: crosswordPath);

    final dropdownItems = list
        .map((Suggestion suggestion) => new DropdownMenuItem(
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
    final dropdownItems = crosswordSources
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
