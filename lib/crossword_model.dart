import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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

class StaticCrossword extends StatelessWidget {
  final Grid grid;
  final List<Clue> acrossClues;
  final List<Clue> downClues;

  StaticCrossword({this.acrossClues, this.downClues, this.grid}) {
    // new Timer.periodic(Duration(seconds: 5), (Timer t) => )
  }

  Widget build(BuildContext context) {
    return Column(
      children: [
        // grid,
        StreamBuilder(
          stream: streamGrids(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data;
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
        ListView(
          padding: EdgeInsets.all(5),
          shrinkWrap: true,
          children: acrossClues,
        ),
      ],
    );
  }

// {"grid":{"width":15,"height":15,"cells":[]},"clues":{"across":[{"number":1,"surface":"Mountain ledge offering place of refreshment for one (7)","length":7,"answer":"SCAFELL","position":{"row":0,"column":0},"span_info":{"linear_span":[{"row":0,"column":0},{"row":0,"column":1},{"row":0,"column":2},{"row":0,"column":3},{"row":0,"column":4},{"row":0,"column":5},{"row":0,"column":6}],"full_span":[{"row":0,"column":0},{"row":0,"column":1},{"row":0,"column":2},{"row":0,"column":3},{"row":0,"column":4},{"row":0,"column":5},{"row":0,"column":6}],"overflow_clues":[],"underflow_clues":[]}}
  factory StaticCrossword.fromJSON(Map<String, dynamic> json) {
    final allClues = json["clues"];
    final aClues = allClues["across"];
    final dClues = allClues["down"];
    return StaticCrossword(
        acrossClues:
            aClues.map<Clue>((jsonClue) => Clue.fromJSON(jsonClue)).toList(),
        downClues:
            dClues.map<Clue>((jsonClue) => Clue.fromJSON(jsonClue)).toList(),
        grid: Grid.fromJSON(json["grid"]));
  }
}

Future<StaticCrossword> fetchCrosswordSkeleton() async {
  final addr = 'https://csolve.herokuapp.com/crossword/guardian-cryptic/28089';
  final response = await http.get(addr);

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return StaticCrossword.fromJSON(json.decode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

// class Row {
//   final List<CellModel> cells;

//   Row({this.cells});

//   factory Row.fromJSON(List<dynamic> jsonIn) {
//     final parsed = jsonIn.map((e) => CellModel.fromJSON(e)).toList();
//     return Row(cells: parsed);
//   }
// }

Stream<Grid> streamGrids() async* {
  yield* Stream.periodic(Duration(seconds: 5), (_) {
    return fetchCrossword();
  }).asyncMap(
    (value) async => await value,
  );
}

class Grid extends StatelessWidget {
  final int width;
  final int height;
  final List<List<CellModel>> rows;

  Grid({this.width, this.height, this.rows});

  Widget build(BuildContext context) {
    final builder = (BuildContext context, i) {
      final row = i ~/ 15;
      final col = i % 15;
      rows[row][col].rowIndex = row;
      rows[row][col].colIndex = col;
      return rows[row][col];
    };

    return Container(
        color: Colors.white30,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: width * height,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: width),
          itemBuilder: builder,
        ));
  }

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

class CellModel extends StatelessWidget {
  final int number;
  // final bool open;
  final Value value;

  // TODO: this is set at build time - yuk.
  int rowIndex;
  int colIndex;

  CellModel({this.number, this.value});

  String charToJson(String charToSet) {
    return charToSet.isEmpty
        ? '{"row":$rowIndex,"col":$colIndex,"value":"Open"}'
        : '{"row":$rowIndex,"col":$colIndex,"value":{"Char":{"value":"$charToSet"}}}';
  }

  void sendValueUpdate(String charToSet) {
    final addr =
        'https://csolve.herokuapp.com/solve/guardian-cryptic/28089/the-everymen/set_cell';
    final body = charToJson(charToSet);
    http.post(
      addr,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
  }

  Widget build(BuildContext context) {
    var controller = TextEditingController(
      text: value.filled ? value.value : null,
    );
    controller.selection = TextSelection(baseOffset: 0, extentOffset: 0);

    // onChanged we want to :
    // get the latest value, and update the box so that it's only one upper case
    // letter
    // Send the update to the server with the single letter value.
    //
    // Using onChanged rather than a controller listener ensures we are only
    // notified about user changes here, and not our own network updates.
    final userChanged = (String value) {
      debugPrint("DEBUG PRINT: Controller.text is");
      debugPrint("${controller.text}");
      controller.value = controller.value.copyWith(
        // any nicer null syntax i can use here?
        text: controller.text.isEmpty ? null : controller.text[0].toUpperCase(),
        selection: TextSelection(baseOffset: 0, extentOffset: 0),
      );
      sendValueUpdate(controller.text);
    };

    var _fillColour = value.open ? Colors.white : Colors.black;

    // Hmm, this doesn't do anything, but I can't recall what I meant to do here.
    final _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _fillColour = Colors.blue;
      }
    });

    if (value.open) {
      final t = TextField(
        controller: controller,
        onChanged: userChanged,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      );

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: _fillColour,
        ),
        child: Center(child: t),
      );
    } else {
      return Container(
          decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.black,
      ));
    }
  }

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
  final addr =
      'https://csolve.herokuapp.com/solve/guardian-cryptic/28089/the-everymen/get';
  final response = await http.get(addr);
  // print(response.body);

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Grid.fromJSON(json.decode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}
