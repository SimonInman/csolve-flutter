import 'cell.dart';

class Grid {
  final int width;
  final int height;
  final List<List<CellModel>> rows;

  Grid({this.width, this.height, this.rows});

  static List<CellModel> _rowFromJSON(dynamic jsonIn) {
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
