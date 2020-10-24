import 'package:csolve/models/cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Cell extends StatefulWidget {
  final int number;
  final Value value;
  final Function(String) onChange;
  final bool highlight;
  final Function() onFocus;
  final Function() onAdvanceCursor;

  /// Should this square be focused on construction?
  // final bool autoFocus;

  /// Where the cursor should move next, if this cell is typed in.
  ///
  /// Will be null if this cell is not focused.
  // final FocusNode nextFocus;

  /// Focus for this cell, if it is next-in-line to be focused.
  ///
  /// Will be null if this cell is not next-in-line to be focused.
  final FocusNode thisFocus;

  Cell({
    Key key,
    @required this.number,
    @required this.value,
    @required this.onChange,
    @required this.highlight,
    @required this.onFocus,
    @required this.onAdvanceCursor,
    // @required this.autoFocus,
    // this.nextFocus,
    this.thisFocus,
  }) : super(key: key);

  @override
  _CellState createState() => _CellState();
}

class _CellState extends State<Cell> {
  Widget build(BuildContext context) {
    if (!widget.value.open) {
      return Container(
          decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.black,
      ));
    }

    var controller = TextEditingController(
      text: widget.value.filled ? widget.value.value : null,
    );
    controller.selection = TextSelection(baseOffset: 0, extentOffset: 0);
    final FocusNode focusNode = Focus.of(context);
    final bool hasFocus = focusNode.hasFocus;

    Color boxColour;
    if (hasFocus) {
      boxColour = Colors.blue.shade700;
    } else if (widget.highlight) {
      boxColour = Colors.blue.shade100;
    } else {
      boxColour = Colors.white;
    }

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
      // Update parent with state change...
      widget.onChange(controller.text);
      if (controller.text.isNotEmpty) {
        // ...but only advance cursor and remove focus from this node if there's
        // some content.
        focusNode.unfocus();
        widget.onAdvanceCursor();

        // TODO: The above has a few problems:
        // 1) We get multiple cursors despite unfocusing.
        // 2) For some reason, having either of unfocus/onAdvanceCursor breaks
        //    the controller.value change. I can't really understand this -
        //    perhaps the parent rebuilts "over" the update? But it breaks even
        //    in a post-frame callback.
        // 3) We are using two different focus nodes, so it's quite confusing.
        //
        // Realistically want to use another method - I think an
        // OrderedTraversalGroup could potentially work.
      }
    };

    final t = TextField(
      autocorrect: false,
      controller: controller,
      onChanged: userChanged,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.black),
      onTap: widget.onFocus,
      // autofocus: widget.autoFocus,
      focusNode: widget.thisFocus,
    );

    final square = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: boxColour,
      ),
      child: Center(child: t),
    );

    if (widget.number != null) {
      return Stack(children: [
        square,
        Text(
          '${widget.number}',
          style: TextStyle(fontSize: 11),
        ),
      ]);
    } else {
      return square;
    }
  }
}
