import 'package:flutter/material.dart';

import 'cell_index.dart';

class Clue extends StatelessWidget {
  final int number;
  final String surface;
  final int length;
  // Answer not present for some puzzles as they are not neccesarily published
  // by sites. Follow on clues also do not have answers.
  final String? answer;
  final Index position;
  final List<Index> span;

  Clue(
      {required this.number,
      required this.surface,
      required this.length,
      required this.answer,
      required this.position,
      required this.span});

  /// Where should the cursor move after [index] is filled?
  Index? nextSquare(Index index) {
    var last = span[0];
    for (final i in this.span.sublist(1)) {
      if (last == index) {
        return i;
      }
      last = i;
    }
    return null;
  }

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
    final boldStyle = new TextStyle(fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
      child: RichText(
        text: new TextSpan(
          style: new TextStyle(color: Colors.black),
          children: <TextSpan>[
            new TextSpan(text: '$number. ', style: boldStyle),
            new TextSpan(text: surface)
          ],
        ),
      ),
    );
  }
}
