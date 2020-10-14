import 'dart:async';

import 'package:csolve/models/cell_index.dart';
import 'package:csolve/models/clue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../crossword_model.dart';
import 'cell.dart';

/// A user update to a cell in the grid.
class GridUpdate {
  final int row;
  final int column;
  // Guarenteed to be only one character - there's no char type.
  final String value;

  GridUpdate(this.row, this.column, this.value) : assert(value.length <= 1);
}

/// Used to describe where the user has clicked and (TODO) the typing direction.
class Cursor {
  final int row;
  final int column;

  Cursor(this.row, this.column);
}

/// A grid of cells allowing the user to enter letters.
///
/// User updates can be streamed to the caller using [streamController].
class LetterGrid extends StatefulWidget {
  final int width;
  final int height;
  final List<List<CellModel>> rows;
  final StreamController<GridUpdate> streamController;

  /// User clicks on a [Cell] - what Clue(s) is that [Cell] part of?
  final List<Clue> Function(Cursor) clueMap;

  LetterGrid(
      {@required this.width,
      @required this.height,
      @required this.rows,
      @required this.streamController,
      @required this.clueMap});

  @override
  State<StatefulWidget> createState() => __LetterGridState();
}

class __LetterGridState extends State<LetterGrid> {
  //TODO this should start blank
  Cursor focusedSquare = Cursor(0, 0);
  List<Index> lightHighlights;
  Clue currentClue;

  void onFocus(int row, int column) {
    setState(() {
      focusedSquare = Cursor(row, column);
      currentClue = _updateCurrentClue(focusedSquare);
      lightHighlights = currentClue?.span;
    });
  }

  Clue _updateCurrentClue(Cursor focusedSquare) {
    final clues = widget.clueMap(focusedSquare);
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

  Widget build(BuildContext context) {
    return Column(
      children: [
        // TODO: prettify this.
        Text((currentClue == null) ? '' : currentClue.surface),
        Container(
            color: Colors.white30,
            child: GridView.builder(
              shrinkWrap: true,
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

    final highlighted = lightHighlights?.contains(Index(row, col));
    return Focus(
      child: Builder(
        builder: (BuildContext context) => Cell(
          number: cellModel.number,
          value: cellModel.value,
          onChange: (string) =>
              widget.streamController.add(GridUpdate(row, col, string)),
          highlight: highlighted ?? false,
          onFocus: () => onFocus(row, col),
        ),
      ),
    );
  }
}
