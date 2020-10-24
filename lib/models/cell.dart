class Value {
  final bool open;
  final bool filled;
  final String value;

  Value({this.open, this.filled, this.value});

  factory Value.fromJSON(json) {
    if (json is Map) {
      final charValue = json["Char"]["value"];
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
  final int number;
  final Value value;

  CellModel({this.number, this.value});

  factory CellModel.fromJSON(json) {
    return CellModel(
      number: json["number"],
      value: Value.fromJSON(json["value"]),
    );
  }
}
