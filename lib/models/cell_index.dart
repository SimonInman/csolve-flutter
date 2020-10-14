import 'package:quiver/core.dart';

class Index {
  final int row;
  final int column;

  Index(this.row, this.column);

  factory Index.fromJSON(json) {
    return Index(json["row"], json["column"]);
  }

  // TODO this is silly, just think of a better interface here.
  bool operator ==(o) => o is Index && o.column == column && o.row == row;

  int get hashCode => hash2(row, column);
}
