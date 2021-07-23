import 'package:flutter/material.dart';

class Suggestion {
  final String id;
  final String? helpfulTag;

  Suggestion({
    required this.id,
    this.helpfulTag,
  });

  String prettyPrint() {
    return '$id: ($helpfulTag)';
  }

  factory Suggestion.fromJSON(json) {
    return Suggestion(
      id: json["id"],
      helpfulTag: json["helpful_tag"],
    );
  }
}
