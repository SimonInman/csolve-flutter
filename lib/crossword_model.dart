import 'dart:async';
import 'dart:convert';

import 'package:csolve/components/letter_grid.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const CROSSWORD = 'guardian-cryptic/28259';

// TODO new function:
// Highlight active square
// scroll to currently selected clue
// Display current clue across top?
// Prettify answer numbers
// Fade clue to grey when complete
// When user first clicks cell, the cursor can be positioned at the end, which breaks the update.

/// Wraps the main Crossword, providing loading spinner and handling errors.
class CrosswordLoader extends StatelessWidget {
  Widget build(BuildContext context) {
    return FutureBuilder<StaticCrossword>(
        future: fetchCrosswordSkeleton(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data;
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        });
  }
}

// I'm not totally clear if having this as Stateful to handle disposal of the
// StreamController is correct.
class StaticCrossword extends StatefulWidget {
  final Grid grid;
  final List<Clue> acrossClues;
  final List<Clue> downClues;

  StaticCrossword({Key key, this.acrossClues, this.downClues, this.grid})
      : super(key: key);

  factory StaticCrossword.fromJSON(Map<String, dynamic> json) {
    final allClues = json["clues"];
    final aClues = allClues["across"];
    final dClues = allClues["down"];

    parseClues(clues) =>
        clues.map<Clue>((jsonClue) => Clue.fromJSON(jsonClue)).toList();
    return StaticCrossword(
        acrossClues: parseClues(aClues),
        downClues: parseClues(dClues),
        grid: Grid.fromJSON(json["grid"]));
  }

  @override
  State<StatefulWidget> createState() {
    return StaticCrosswordState();
  }
}

class StaticCrosswordState extends State<StaticCrossword> {
  final StreamController<GridUpdate> streamController = new StreamController();

  @override
  void initState() {
    super.initState();
    streamController.stream.listen(sendValueUpdate);
  }

  static String charToJson(int rowIndex, int colIndex, String charToSet) {
    return charToSet.isEmpty
        ? '{"row":$rowIndex,"col":$colIndex,"value":"Open"}'
        : '{"row":$rowIndex,"col":$colIndex,"value":{"Char":{"value":"$charToSet"}}}';
  }

  static void sendValueUpdate(GridUpdate update) {
    final addr =
        'https://csolve.herokuapp.com/solve/$CROSSWORD/the-everymen/set_cell';
    final body = charToJson(update.row, update.column, update.value);
    http.post(
      addr,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
  }

  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder(
          stream: streamGrids(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildGridWidget(snapshot.data);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
        Flexible(
          child: ListView(
            padding: EdgeInsets.all(5),
            children: widget.acrossClues + widget.downClues,
          ),
        ),
      ],
    );
  }

  Widget _buildGridWidget(Grid grid) {
    return LetterGrid(grid.width, grid.height, grid.rows, streamController);
  }

  @override
  void dispose() {
    super.dispose();
    streamController.close();
  }
}

Future<StaticCrossword> fetchCrosswordSkeleton() async {
  final addr = 'https://csolve.herokuapp.com/crossword/$CROSSWORD';
  final response = await http.get(addr);

  if (response.statusCode == 200) {
    return StaticCrossword.fromJSON(json.decode(response.body));
  } else {
    throw Exception('Failed to load album');
  }
}

Stream<Grid> streamGrids() async* {
  yield* Stream.periodic(Duration(seconds: 5), (_) {
    return fetchCrossword();
  }).asyncMap(
    (value) async => await value,
  );
}

class Grid {
  final int width;
  final int height;
  final List<List<CellModel>> rows;

  Grid({this.width, this.height, this.rows});

  static List<CellModel> _rowFromJSON(dynamic jsonIn) {
    // debugPrint("called _rowFromJSON");
    List<CellModel> parsed =
        jsonIn.map<CellModel>((e) => CellModel.fromJSON(e)).toList();
    return parsed;
  }

  factory Grid.fromJSON(Map<String, dynamic> jsonIn) {
    final List<dynamic> cells = jsonIn['cells'];

    final parsedRows = cells.map<List<CellModel>>(_rowFromJSON).toList();
    return Grid(
      width: jsonIn['width'],
      height: jsonIn['height'],
      rows: parsedRows,
    );
  }
}

class Value {
  final bool open;
  final bool filled;
  final String value;

  Value({this.open, this.filled, this.value});

  factory Value.fromJSON(json) {
    if (json is Map) {
      final charValue = json["Char"]["value"];
      return Value(open: true, filled: true, value: charValue);
    } else {
      if (json == "Closed") {
        return Value(open: false, filled: false);
      } else if (json == "Open") {
        return Value(open: true, filled: false);
      } else {
        throw Exception("UNKNOWN VALUE: $json");
      }
    }
  }
}

class CellModel {
  final int number;
  final Value value;

  CellModel({this.number, this.value});

  factory CellModel.fromJSON(json) {
    return CellModel(
      number: json["number"],
      value: Value.fromJSON(json["value"]),
    );
  }
}

class Clue extends StatelessWidget {
  final int number;
  final String surface;
  final int length;
  final String answer;

  Clue({this.number, this.surface, this.length, this.answer});

  factory Clue.fromJSON(json) {
    return Clue(
      number: json["number"],
      surface: json["surface"],
      length: json["length"],
      answer: json["answer"],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = '$number . $surface';
    return Text(text);
  }
}

Future<Grid> fetchCrossword() async {
  final addr = 'https://csolve.herokuapp.com/solve/$CROSSWORD/the-everymen/get';
  final response = await http.get(addr);

  if (response.statusCode == 200) {
    return Grid.fromJSON(json.decode(response.body));
  } else {
    throw Exception('Failed to load album');
  }
}
