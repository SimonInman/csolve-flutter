import 'dart:async';

import 'package:csolve/components/letter_grid.dart';
import 'package:flutter/material.dart';

import 'models/cell_index.dart';
import 'models/clue.dart';
import 'models/clue_mapper.dart';
import 'models/grid.dart';
import 'network/network.dart';

const CROSSWORD = 'guardian-cryptic/28259';

const clueColumnMinSize = 360;
final minSizeForWide = maxGridWidth + 2 * clueColumnMinSize;

const _wideViewPadding = 10.0;
const _clueSidePadding = 8.0;
final clueSidePadding =
    const EdgeInsets.only(left: _clueSidePadding, right: _clueSidePadding);

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
    Key? key,
    required this.crosswordPath,
    required this.crosswordId,
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
      {Key? key, required this.crosswordPath, required this.crosswordId})
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
            return snapshot.data!;
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
    Key? key,
    required this.acrossClues,
    required this.downClues,
    required this.grid,
    required this.crosswordPath,
    required this.crosswordId,
  })  : mapper = ClueMapper.fromClues(acrossClues, downClues),
        super(key: key);

  factory StaticCrossword.fromJSON({
    required Map<String, dynamic> json,
    required String crosswordPath,
    required String crosswordId,
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
  Clue? currentClue;

  @override
  void initState() {
    super.initState();
    streamController.stream.listen((update) =>
        sendValueUpdate(update, widget.crosswordPath, widget.crosswordId));
  }

  Widget _clueHeaders(String acrossOrDown) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        acrossOrDown,
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: streamGrids(
        crosswordId: widget.crosswordId,
        crosswordPath: widget.crosswordPath,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _build(context, snapshot.data as Grid);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }

  Clue? _updateCurrentClue(Index focusedSquare) {
    final clues = widget.mapper.call(focusedSquare)!;
    if (clues.length == 1) {
      return clues[0];
    }
    // If we already had the user focused on one clue, it means they want to
    // switch to the other clue. Otherwise, arbitrarily return the first clue.
    // ?? Is this going to work? not sure if focus triggers a second time.
    if (clues.length == 2) {
      if (currentClue == clues[0]) {
        return clues[1];
      } else {
        return clues[0];
      }
    }
    // Should never happen.
    return null;
  }

  void onUpdateGridFocus(Index cursor) {
    setState(() {
      currentClue = _updateCurrentClue(cursor);
    });
  }

  Widget _build(BuildContext context, Grid grid) {
    return MediaQuery.of(context).size.width > minSizeForWide
        ? _wideLayout(context, grid)
        : _verticalLayout(context, grid);
  }

  Widget _verticalLayout(BuildContext context, Grid grid) {
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
          _maybeSelectedClue(),
          _buildGridWidget(grid),
          _clueColumn(clueWidgets),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context, Grid grid) {
    return Column(
      children: [
        _maybeSelectedClue(),
        Padding(
          padding: const EdgeInsets.all(_wideViewPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridWidget(grid),
              _clueColumn([_clueHeaders('Across'), ...widget.acrossClues]),
              _clueColumn([_clueHeaders('Down'), ...widget.downClues]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _clueColumn(List<Widget> headersAndClues) {
    return Flexible(
      child: Padding(
        padding: clueSidePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: headersAndClues,
        ),
      ),
    );
  }

  Widget _maybeSelectedClue() => Text((currentClue == null)
      ? ''
      : '${currentClue!.number}: ${currentClue!.surface}');

  Widget _buildGridWidget(Grid grid) {
    return LetterGrid(
      width: grid.width,
      height: grid.height,
      rows: grid.rows,
      streamController: streamController,
      currentClue: currentClue,
      updateFocus: onUpdateGridFocus,
    );
  }

  @override
  void dispose() {
    super.dispose();
    streamController.close();
  }
}

Stream<Grid> streamGrids({
  required String crosswordPath,
  required String crosswordId,
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
