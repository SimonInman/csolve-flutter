import 'dart:convert';

import 'package:csolve/components/letter_grid.dart';
import 'package:csolve/models/grid.dart';
import 'package:csolve/models/suggestion.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';

import '../crossword_model.dart';

// Code that accesses the network.

const SITE_ADDR = 'https://csolve.herokuapp.com/';

Future<Grid> fetchCrossword({
  required String crosswordPath,
  required String crosswordId,
}) async {
  final addr = '$SITE_ADDR/solve/$crosswordPath/$crosswordId/the-everymen/get';
  final response = await http.get(Uri.parse(addr));

  if (response.statusCode == 200) {
    return Grid.fromJSON(json.decode(response.body));
  } else {
    throw Exception('Failed to load the crossword');
  }
}

Future<StaticCrossword> fetchCrosswordSkeleton({
  required String crosswordPath,
  required String crosswordId,
}) async {
  final addr = '$SITE_ADDR/crossword/$crosswordPath/$crosswordId';

  final response = await http.get(Uri.parse(addr));

  if (response.statusCode == 200) {
    return StaticCrossword.fromJSON(
      json: json.decode(response.body),
      crosswordId: crosswordId,
      crosswordPath: crosswordPath,
    );
  } else {
    throw Exception('Failed to load album');
  }
}

Future<List<Suggestion>> fetchSuggestions(
    {required String crosswordPath}) async {
  final addr = '$SITE_ADDR/suggestions/$crosswordPath';
  final response = await http.get(Uri.parse(addr));

  if (response.statusCode == 200) {
    final list = json.decode(response.body);
    return list
        .map<Suggestion>((suggestion) => Suggestion.fromJSON(suggestion))
        .toList();
  } else {
    throw Exception('failed to load suggestions');
  }
}

String charToJson({
  required int rowIndex,
  required int colIndex,
  required String charToSet,
}) {
  return charToSet.isEmpty
      ? '{"row":$rowIndex,"col":$colIndex,"value":"Open"}'
      : '{"row":$rowIndex,"col":$colIndex,"value":{"FilledChar":{"value":"$charToSet"}}}';
}

void sendValueUpdate(
  GridUpdate update,
  String crosswordPath,
  String crosswordId,
) {
  final addr =
      '$SITE_ADDR/solve/$crosswordPath/$crosswordId/the-everymen/set_cell';
  final body = charToJson(
      rowIndex: update.row, colIndex: update.column, charToSet: update.value);
  http.post(
    Uri.parse(addr),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: body,
  );
}
