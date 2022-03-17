import 'dart:async';

import 'package:csolve/components/letter_grid.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';


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
      : super(key: key);

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

class GivenAnswers {
  final List<Clue> acrossClues;
  final List<Clue> downClues;
  // final List<List<String>> acrossAnswers;
  // final List<List<String>> downAnswers;
  final List<List<String>> answers;

  GivenAnswers(this.acrossClues, this.downClues) : 

  answers = [_blankClue(), _blankClue(), _blankClue(), _blankClue(), _blankClue()] ;

void updateAnswer(int row, int col, String answer) {
  print('updating answer');
  assert(answer.isEmpty || answer.length == 1);
  answers[row][col] = answer;
}

bool allCorrect() {
  print('checking all correct');
   final anyIncorrect = acrossClues.any((clue) => !clueCorrect(clue)) || downClues.any((clue) => !clueCorrect(clue));
   print('returning ${!anyIncorrect}');
   return !anyIncorrect;
}

bool clueCorrect(Clue clue) {
  assert(clue.answer!.isNotEmpty);
  final matching = clue.span.mapIndexed((int i, Index gridPosition) {
    return (answers[gridPosition.row][gridPosition.column] == clue.answer![i]) ;
  });
  
  return !matching.any((doesMatch) => !doesMatch);
}

static List<String> _blankClue() => ['','','','','',];

}

class StaticCrosswordState extends State<StaticCrossword> {
  final StreamController<GridUpdate> streamController = new StreamController();
  Clue? currentClueGrid1;
  Clue? currentClueGrid2;
  int currentFocusedGrid = 1;
  // What's the desired way of initialising these using info from the widget?
  // these should not be null
  late GivenAnswers grid1Answers ;
  late GivenAnswers grid2Answers ;

  @override
  void initState() {
    super.initState();
  grid1Answers = GivenAnswers(widget.acrossClues, widget.downClues);
  grid2Answers = GivenAnswers(widget.acrossClues, widget.downClues);
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
    return _build(context, widget.grid);
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

  Clue? _updateCurrentClueGrid1(Index focusedSquare) {
    final clues = widget.mapper.call(focusedSquare)!;
    if (clues.length == 1) {
      return clues[0];
    }
    // If we already had the user focused on one clue, it means they want to
    // switch to the other clue. Otherwise, arbitrarily return the first clue.
    // ?? Is this going to work? not sure if focus triggers a second time.
    if (clues.length == 2) {
      if (currentClueGrid1 == clues[0]) {
        return clues[1];
      } else {
        return clues[0];
      }
    }
    // Should never happen.
    return null;
  }

  Clue? _updateCurrentClueGrid2(Index focusedSquare) {
    final clues = widget.mapper.call(focusedSquare)!;
    if (clues.length == 1) {
      return clues[0];
    }
    // If we already had the user focused on one clue, it means they want to
    // switch to the other clue. Otherwise, arbitrarily return the first clue.
    // ?? Is this going to work? not sure if focus triggers a second time.
    if (clues.length == 2) {
      if (currentClueGrid2 == clues[0]) {
        return clues[1];
      } else {
        return clues[0];
      }
    }
    // Should never happen.
    return null;
  }


  // Clue? _updateCurrentClue(Index focusedSquare) {
  //   final clues = widget.mapper.call(focusedSquare)!;
  //   if (clues.length == 1) {
  //     return clues[0];
  //   }
  //   // If we already had the user focused on one clue, it means they want to
  //   // switch to the other clue. Otherwise, arbitrarily return the first clue.
  //   // ?? Is this going to work? not sure if focus triggers a second time.
  //   if (clues.length == 2) {
  //     if (currentClue == clues[0]) {
  //       return clues[1];
  //     } else {
  //       return clues[0];
  //     }
  //   }
  //   // Should never happen.
  //   return null;
  // }

  // void onUpdateGridFocus(Index cursor) {
  //   setState(() {
  //     currentClueG = _updateCurrentClue(cursor);
  //   });
  // }

  void onUpdateGrid1Focus(Index cursor) {
    setState(() {
      currentClueGrid1 = _updateCurrentClueGrid1(cursor);
      currentFocusedGrid = 1;
    });
  }

  void onUpdateGrid2Focus(Index cursor) {
    setState(() {
      currentClueGrid2 = _updateCurrentClueGrid2(cursor);
      currentFocusedGrid = 2;
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
          // _maybeSelectedClue(),
          _buildGridWidget(grid, 1),
          _clueColumn(clueWidgets),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context, Grid grid) {
    return Column(
      children: [
        // _maybeSelectedClue(),
        Padding(
          padding: const EdgeInsets.all(_wideViewPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGridWidget(grid, 1 ),
              _buildGridWidget(grid, 2),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _clueColumn([_clueHeaders('Across'), ...widget.acrossClues]),
              _clueColumn([_clueHeaders('Down'), ...widget.downClues]),
                ],
              ),
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

  // Widget _maybeSelectedClue() => Text((currentClue == null)
  //     ? ''
  //     : '${currentClue!.number}: ${currentClue!.surface}');

  Widget _buildGridWidget(Grid grid, int gridNumber) {
    final gridAnswers = gridNumber == 1 ? grid1Answers : grid2Answers;
    final thisGridFocused = gridNumber == currentFocusedGrid;
    final focusUpdate = gridNumber == 1 ? onUpdateGrid1Focus : onUpdateGrid2Focus;
    final currentClue = gridNumber == 1 ? currentClueGrid1 : currentClueGrid2;
    return LetterGrid(
      width: grid.width,
      height: grid.height,
      rows: grid.rows,
      streamController: streamController,
      currentClue: currentClue,
      updateFocus: focusUpdate,
      thisGridFocused: thisGridFocused,
      onChange: (int row, int col, String answer) => updateAnswer(gridAnswers, row, col, answer),
      allCorrect: gridAnswers.allCorrect(),
    );
  }

  void updateAnswer(GivenAnswers answers, int row, int col, String answer) {
    setState(() {
      answers.updateAnswer(row, col, answer);
    });

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
