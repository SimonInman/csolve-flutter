import 'package:csolve/models/cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Cell extends StatefulWidget {
  /// Clue number to be displayed in the cell.
  ///
  /// Null if not the start of a clue.
  final int? number;

  /// The current user-entered value in the cell.
  final Value value;

  /// Whether the cell should be highlighted.
  final bool highlight;

  /// Callback when the user taps on a square.
  final Function() onFocus;

  /// Called when the value of the square is changed.
  final Function(String) onChange;

  /// Callback when the user fills a square with an answer.
  ///
  /// The difference between this and onChange is that onAdvanceCursor is called
  /// only when the square is filled. onChange can be called with a blank entry.
  final Function() onAdvanceCursor;

  /// Whether this cell should request focus.
  final bool isFocused;

  Cell({
    Key? key,
    required this.number,
    required this.value,
    required this.onChange,
    required this.highlight,
    required this.onFocus,
    required this.onAdvanceCursor,
    required this.isFocused,
  }) : super(key: key);

  @override
  _CellState createState() => _CellState();
}

class _CellState extends State<Cell> {
  FocusNode focusNode = new FocusNode();
  TextEditingController controller = new TextEditingController();
  bool justUpdated = false;

  @override
  void initState() {
    focusNode = new FocusNode();
    controller = new TextEditingController();
    super.initState();
  }

  Widget build(BuildContext context) {
    if (!widget.value.open) {
      return Container(
          decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: Colors.black,
      ));
    }

    if (!justUpdated) {
      controller.text = widget.value.filled ? widget.value.value! : '';
    } else {
      setState(() {
        // Only keep the user entered letter for one rebuild - server is source
        // of truth otherwise.
        justUpdated = false;
      });
    }

    controller.selection = TextSelection(baseOffset: 0, extentOffset: 0);

    if (widget.isFocused) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
    }

    Color boxColour;
    if (widget.isFocused) {
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
    // - Tell the State that we've just updated. Otherwise, when the cell is
    // rebuilt immediately, the value will get overwritten by the server value.
    //
    // Using onChanged rather than the controller listener ensures we are only
    // notified about user changes here, and not our own network updates.
    final userChanged = (String value) {
      controller.value = controller.value.copyWith(
        // any nicer null syntax i can use here?
        text: controller.text.isEmpty ? '' : controller.text[0].toUpperCase(),
        selection: TextSelection(baseOffset: 0, extentOffset: 0),
      );

      setState(() {
        justUpdated = true;
      });

      // Update parent with state change...
      widget.onChange(controller.text);
      if (controller.text.isNotEmpty) {
        // ...but only advance cursor and remove focus from this node if there's
        // some content.
        widget.onAdvanceCursor();

        // TODO: Calling onAdvanceCursor breaks the controller.value change, and
        // the user doesn't see the value until the next network update.
        // Presumably because the controller is not inn the State. Therefore
        // make it part of the state.
      }
    };

    final t = TextField(
      autocorrect: false,
      controller: controller,
      onChanged: userChanged,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.black),
      onTap: widget.onFocus,
      focusNode: focusNode,
      // Have to add some padding because the TextField doesn't center properly?
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(top: 2.0, left: 2.0),
        isDense: true,
      ),
    );

    final square = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: boxColour,
      ),
      child: t,
    );

    if (widget.number != null) {
      return Stack(children: [
        // Without this fill, the bordered square shrinks for some reason...?
        Positioned.fill(child: square),
        Padding(
          padding: const EdgeInsets.only(left: 2.0),
          child: Text(
            '${widget.number}',
            style: TextStyle(fontSize: 9, color: Colors.black),
          ),
        ),
      ]);
    } else {
      return square;
    }
  }
}
