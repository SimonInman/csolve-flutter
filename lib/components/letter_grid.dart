import 'dart:async';

import 'package:csolve/models/cell.dart';
import 'package:csolve/models/cell_index.dart';
import 'package:csolve/models/clue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/check.dart';
import 'cell.dart';

/// A user update to a cell in the grid.
class GridUpdate {
  final int row;
  final int column;
  // Guarenteed to be only one character - there's no char type.
  final String value;

  GridUpdate(this.row, this.column, this.value) : assert(value.length <= 1);
}

/// A grid of cells allowing the user to enter letters.
///
/// User updates can be streamed to the caller using [streamController].
class LetterGrid extends StatefulWidget {
  final int width;
  final int height;
  final List<List<CellModel>> rows;
  final StreamController<GridUpdate> streamController;
  final Clue currentClue;
  List<Index> lightHighlights;

  // Callback when the user clicks on a square.
  final void Function(Index) updateFocus;

  LetterGrid({
    @required width,
    @required height,
    @required rows,
    @required streamController,
    @required this.currentClue,
    @required updateFocus,
  })  : updateFocus = checkNotNull(updateFocus),
        width = checkNotNull(width),
        height = checkNotNull(height),
        rows = checkNotNull(rows),
        streamController = checkNotNull(streamController),
        lightHighlights = currentClue?.span;

  @override
  State<StatefulWidget> createState() => __LetterGridState();
}

class __LetterGridState extends State<LetterGrid> {
  //TODO this should start blank
  Index focusedSquare = Index(0, 0);
  Index nextFocusIndex;
  FocusNode nextFocusNode;

  @override
  void initState() {
    nextFocusNode = new FocusNode();
    super.initState();
  }

  @override
  void didUpdateWidget(LetterGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    nextFocusIndex = widget.currentClue
        ?.nextSquare(Index(focusedSquare.row, focusedSquare.column));
  }

  void onFocus(int row, int column) {
    focusedSquare = Index(row, column);
    widget.updateFocus(Index(row, column));
  }

  void onAdvanceCursor() {
    setState(() {
      // probably this nextFocusIndex doesn't even need to be stateful any more?
      // it can jjust be a local variable
      if (nextFocusIndex != null) {
        nextFocusNode.requestFocus();
        focusedSquare = Index(nextFocusIndex.row, nextFocusIndex.column);
        nextFocusIndex = widget.currentClue
            .nextSquare(Index(nextFocusIndex.row, nextFocusIndex.column));
      }
    });
  }

  @override
  void dispose() {
    nextFocusNode.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            color: Colors.white30,
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.width * widget.height,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.width),
              itemBuilder: _cellBuilder,
            )),
      ],
    );
  }

  Widget _cellBuilder(BuildContext context, i) {
    final row = i ~/ widget.width;
    final col = i % widget.width;
    final cellModel = widget.rows[row][col];

    final highlighted = widget.lightHighlights?.contains(Index(row, col));

    // When the user fills in the current square, we want to request focus on
    // the next square. This requires handing our FocusNode to both the focused
    // square and the next square.
    // FocusNode nextFocus;
    FocusNode thisFocus;
    if (nextFocusIndex != null && nextFocusIndex.equal(row, col)) {
      thisFocus = nextFocusNode;
    }

    return Focus(
      child: Builder(
        builder: (BuildContext context) => Cell(
          number: cellModel.number,
          value: cellModel.value,
          onChange: (string) =>
              widget.streamController.add(GridUpdate(row, col, string)),
          highlight: highlighted ?? false,
          onFocus: () => onFocus(row, col),
          onAdvanceCursor: onAdvanceCursor,
          thisFocus: thisFocus,
        ),
      ),
    );
  }
}
