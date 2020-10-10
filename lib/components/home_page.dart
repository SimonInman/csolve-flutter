import 'package:csolve/crossword_model.dart';
import 'package:flutter/material.dart';

const SOURCES = [
  'guardian-cryptic',
  'guardian-quiptic',
  'guardian-prize',
  'independent',
  'nyt',
  'new-yorker',
];

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String crosswordPath = 'independent';
  String crosswordId = '';
  // TODO this isn't actually used yet
  String solveGroup = 'the-everymen';

  @override
  Widget build(BuildContext context) {
    final dropdownItems = SOURCES
        .map((value) =>
            new DropdownMenuItem(value: value, child: new Text(value)))
        .toList();

    final dropdown = DropdownButton<String>(
      value: crosswordPath,
      items: dropdownItems,
      style: TextStyle(color: Colors.deepPurple),
      onChanged: (String newValue) {
        setState(() {
          crosswordPath = newValue;
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
                    crosswordId: crosswordId,
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
      dropdown,
      Text(
        'ID',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      idField,
      Text(
        'Solve Group',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      solveGroupField,
      button,
    ]);
  }
}
