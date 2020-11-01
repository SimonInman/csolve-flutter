import 'dart:async';

import 'package:csolve/components/letter_grid.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/cell.dart';
import 'models/clue.dart';
import 'models/clue_mapper.dart';
import 'models/grid.dart';
import 'network/network.dart';

const CROSSWORD = 'guardian-cryptic/28259';

// TODO new function:
// scroll to currently selected clue
// Display current clue across top?
// Prettify answer numbers
// Fade clue to grey when complete
// When user first clicks cell, the cursor can be positioned at the end, which breaks the update.

class CrosswordScreen extends StatelessWidget {
  final String crosswordPath;
  final String crosswordId;

  const CrosswordScreen({
    Key key,
    @required this.crosswordPath,
    @required this.crosswordId,
  })  : assert(crosswordId != null),
        assert(crosswordPath != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(35),
        child: AppBar(
          title: Text('$crosswordPath $crosswordId'),
        ),
      ),
      body: Center(
          child: CrosswordLoader(
        crosswordId: crosswordId,
        crosswordPath: crosswordPath,
      )),
    );
  }
}

/// Wraps the main Crossword, providing loading spinner and handling errors.
class CrosswordLoader extends StatelessWidget {
  final String crosswordPath;
  final String crosswordId;

  const CrosswordLoader(
      {Key key, @required this.crosswordPath, @required this.crosswordId})
      : assert(crosswordId != null),
        assert(crosswordPath != null),
        super(key: key);

  Widget build(BuildContext context) {
    return FutureBuilder<StaticCrossword>(
        future: fetchCrosswordSkeleton(
          crosswordId: crosswordId,
          crosswordPath: crosswordPath,
        ),
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
  // TODO do something more sensible to bring these clues together.
  final List<Clue> acrossClues;
  final List<Clue> downClues;
  final ClueMapper mapper;
  final String crosswordPath;
  final String crosswordId;

  StaticCrossword({
    Key key,
    @required this.acrossClues,
    @required this.downClues,
    @required this.grid,
    @required this.crosswordPath,
    @required this.crosswordId,
  })  : mapper = ClueMapper.fromClues(acrossClues, downClues),
        super(key: key);

  factory StaticCrossword.fromJSON({
    @required Map<String, dynamic> json,
    @required String crosswordPath,
    @required String crosswordId,
  }) {
    final allClues = json["clues"];
    final aClues = allClues["across"];
    final dClues = allClues["down"];

    parseClues(clues) =>
        clues.map<Clue>((jsonClue) => Clue.fromJSON(jsonClue)).toList();
    return StaticCrossword(
      acrossClues: parseClues(aClues),
      downClues: parseClues(dClues),
      grid: Grid.fromJSON(json["grid"]),
      crosswordPath: crosswordPath,
      crosswordId: crosswordId,
    );
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
    streamController.stream.listen((update) =>
        sendValueUpdate(update, widget.crosswordPath, widget.crosswordId));
  }

  static String charToJson({
    @required int rowIndex,
    @required int colIndex,
    @required String charToSet,
  }) {
    return charToSet.isEmpty
        ? '{"row":$rowIndex,"col":$colIndex,"value":"Open"}'
        : '{"row":$rowIndex,"col":$colIndex,"value":{"Char":{"value":"$charToSet"}}}';
  }

  static void sendValueUpdate(
    GridUpdate update,
    String crosswordPath,
    String crosswordId,
  ) {
    final addr =
        'https://csolve.herokuapp.com/solve/$crosswordPath/$crosswordId/the-everymen/set_cell';
    final body = charToJson(
        rowIndex: update.row, colIndex: update.column, charToSet: update.value);
    http.post(
      addr,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
  }

  Widget _clueHeaders(String acrossOrDown) {
    return Text(
      acrossOrDown,
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget build(BuildContext context) {
    List<Widget> clueWidgets = [
      _clueHeaders('Across'),
      ...widget.acrossClues,
      _clueHeaders('Down'),
      ...widget.downClues
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder(
            stream: streamGrids(
              crosswordId: widget.crosswordId,
              crosswordPath: widget.crosswordPath,
            ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: clueWidgets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridWidget(Grid grid) {
    return LetterGrid(
      width: grid.width,
      height: grid.height,
      rows: grid.rows,
      streamController: streamController,
      clueMap: widget.mapper.call,
    );
  }

  @override
  void dispose() {
    super.dispose();
    streamController.close();
  }
}

Stream<Grid> streamGrids({
  @required String crosswordPath,
  @required String crosswordId,
}) async* {
  yield await fetchCrossword(
    crosswordId: crosswordId,
    crosswordPath: crosswordPath,
  );
  yield* Stream.periodic(Duration(seconds: 5), (_) {
    return fetchCrossword(
      crosswordId: crosswordId,
      crosswordPath: crosswordPath,
    );
  }).asyncMap(
    (value) async => await value,
  );
}
