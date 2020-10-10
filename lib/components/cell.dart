import 'package:csolve/crossword_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Cell extends StatelessWidget {
  final int number;
  final Value value;
  final Function(String) onChange;

  Cell({this.number, this.value, this.onChange});

  Widget build(BuildContext context) {
    if (!value.open) {
      return Container(
          decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.black,
      ));
    }

    var controller = TextEditingController(
      text: value.filled ? value.value : null,
    );
    controller.selection = TextSelection(baseOffset: 0, extentOffset: 0);

    // onChanged we want to :
    // - Get the latest value, and update the box so that it's only one
    //   upper-case letter (or blank).
    // - Send the update to the Stream with the remaining value.
    //
    // Using onChanged rather than the controller listener ensures we are only
    // notified about user changes here, and not our own network updates.
    final userChanged = (String value) {
      controller.value = controller.value.copyWith(
        // any nicer null syntax i can use here?
        text: controller.text.isEmpty ? '' : controller.text[0].toUpperCase(),
        selection: TextSelection(baseOffset: 0, extentOffset: 0),
      );
      onChange(controller.text);
    };

    final t = TextField(
      controller: controller,
      onChanged: userChanged,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.black),
    );

    final square = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.white,
      ),
      child: Center(child: t),
    );

    if (number != null) {
      return Stack(children: [square, Text('$number')]);
    } else {
      return square;
    }
  }
}
