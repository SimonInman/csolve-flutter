import 'package:csolve/components/letter_grid.dart';
import 'package:flutter/foundation.dart';

import 'cell_index.dart';
import 'clue.dart';

/// Holds information mapping Cells onto Clues.
///
/// This lets us highlight and navigate round clues.
/// The [map] is from an Index to a List of Clues, as a crosser is part of two
/// clues. All open cells should be part of at least one clue.
class ClueMapper {
  final Map<Index, List<Clue>> map;
  ClueMapper({required this.map}) : assert(map != null);

  List<Clue>? call(Index cursor) {
    final index = Index(cursor.row, cursor.column);
    if (map.containsKey(index)) {
      return map[index];
    }
    return null;
  }

  factory ClueMapper.fromClues(List<Clue> acrossClues, List<Clue> downClues) {
    Map<Index, List<Clue>> map = Map();

    for (final clues in [acrossClues, downClues]) {
      for (final clue in clues) {
        final span = clue.span;
        for (final index in span) {
          // This is like default_dict in python.
          map.putIfAbsent(index, () => []).add(clue);
          // map[index] = clue;
        }
      }
    }
    return ClueMapper(map: map);
  }
}
