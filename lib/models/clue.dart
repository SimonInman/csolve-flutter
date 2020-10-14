import 'package:flutter/material.dart';

import 'cell_index.dart';

class Clue extends StatelessWidget {
  final int number;
  final String surface;
  final int length;
  final String answer;
  final Index position;
  final List<Index> span;

  Clue(
      {@required this.number,
      @required this.surface,
      @required this.length,
      @required this.answer,
      @required this.position,
      @required this.span});

  factory Clue.fromJSON(json) {
    Map<String, dynamic> span = json['span_info'];
    List<dynamic> linearSpan = span['linear_span'];
    return Clue(
      number: json["number"],
      surface: json["surface"],
      length: json["length"],
      answer: json["answer"],
      position: Index.fromJSON(json["position"]),
      span: linearSpan.map<Index>((json) => Index.fromJSON(json)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = '$number . $surface';
    return Text(text);
  }
}
