import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';

import '../crossword_model.dart';

// Code that accesses the network.

Future<Grid> fetchCrossword({
  @required String crosswordPath,
  @required String crosswordId,
}) async {
  final addr =
      'https://csolve.herokuapp.com/solve/$crosswordPath/$crosswordId/the-everymen/get';
  final response = await http.get(addr);

  if (response.statusCode == 200) {
    return Grid.fromJSON(json.decode(response.body));
  } else {
    throw Exception('Failed to load the crossword');
  }
}

Future<StaticCrossword> fetchCrosswordSkeleton({
  @required String crosswordPath,
  @required String crosswordId,
}) async {
  assert(crosswordId != null);
  assert(crosswordPath != null);
  final addr =
      'https://csolve.herokuapp.com/crossword/$crosswordPath/$crosswordId';

  final response = await http.get(addr);

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
