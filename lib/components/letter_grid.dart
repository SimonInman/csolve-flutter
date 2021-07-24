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
  final Clue? currentClue;
  List<Index> lightHighlights;

  // Callback when the user clicks on a square.
  final void Function(Index) updateFocus;

  LetterGrid({
    required width,
    required height,
    required rows,
    required streamController,
    required this.currentClue,
    required updateFocus,
  })  : updateFocus = checkNotNull(updateFocus),
        width = checkNotNull(width),
        height = checkNotNull(height),
        rows = checkNotNull(rows),
        streamController = checkNotNull(streamController),
        lightHighlights = currentClue?.span ?? [];

  @override
  State<StatefulWidget> createState() => __LetterGridState();
}

class __LetterGridState extends State<LetterGrid> {
  //TODO this should start blank
  Index focusedSquare = Index(0, 0);

  void onFocus(int row, int column) {
    focusedSquare = Index(row, column);
    widget.updateFocus(focusedSquare);
  }

  /// If we're not at the end of the word, advance the cursor.
  void onAdvanceCursor() {
    setState(() {
      final nextSquare = widget.currentClue?.nextSquare(focusedSquare);
      if (nextSquare != null) {
        focusedSquare = nextSquare;
      }
    });
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

    final highlighted = widget.lightHighlights.contains(Index(row, col));
    final isFocused = focusedSquare.equal(row, col);

    return Focus(
      child: Builder(
        builder: (BuildContext context) => Cell(
          number: cellModel.number,
          value: cellModel.value,
          onChange: (string) =>
              widget.streamController.add(GridUpdate(row, col, string)),
          highlight: highlighted,
          onFocus: () => onFocus(row, col),
          onAdvanceCursor: onAdvanceCursor,
          isFocused: isFocused,
        ),
      ),
    );
  }
}
