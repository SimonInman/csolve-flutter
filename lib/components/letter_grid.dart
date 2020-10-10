import 'dart:async';

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

/// A grid of cells allowing the user to enter letters.
///
/// User updates can be streamed to the caller using [streamController].
class LetterGrid extends StatelessWidget {
  final int width;
  final int height;
  final List<List<CellModel>> rows;
  final StreamController<GridUpdate> streamController;

  LetterGrid(this.width, this.height, this.rows, this.streamController);

  Widget build(BuildContext context) {
    final builder = (BuildContext context, i) {
      final row = i ~/ width;
      final col = i % width;
      final cellModel = rows[row][col];

      return Cell(
        number: cellModel.number,
        value: cellModel.value,
        onChange: (string) =>
            streamController.add(GridUpdate(row, col, string)),
      );
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
}
