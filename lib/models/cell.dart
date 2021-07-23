class Value {
  final bool open;
  final bool filled;
  final String? value;

  Value({required this.open, required this.filled, this.value});

  /// If value is filled, the values are stored in a map.
  // value":{
  //   "FilledChar":{
  //   "value":"A",
  //   "style":{"colour":{"red":0,"green":255,"blue":0},"pattern":"VerticalStripes"}
  //   }
  // }
  factory Value.fromJSON(json) {
    if (json is Map) {
      final charValue = json["FilledChar"]["value"];
      return Value(open: true, filled: true, value: charValue);
    } else {
      if (json == "Closed") {
        return Value(open: false, filled: false);
      } else if (json == "Open") {
        return Value(open: true, filled: false);
      } else {
        throw Exception("UNKNOWN VALUE: $json");
      }
    }
  }
}

class CellModel {
  final int? number;
  final Value value;

  CellModel({this.number, required this.value});

  factory CellModel.fromJSON(json) {
    return CellModel(
      number: json["number"],
      value: Value.fromJSON(json["value"]),
    );
  }
}
