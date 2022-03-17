import 'package:csolve/models/cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

final normalBorder = BorderSide(color: Colors.black, width: 1.0);
final thickBorder = BorderSide(color: Colors.black, width: 2.5);

class Cell extends StatefulWidget {
  /// Model continaing the value of the cell, number (if any), and whether this
  /// cell is the end of a word.
  final CellModel model;

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

  final bool puzzleCompleted;

  Cell({
    Key? key,
    required this.model,
    required this.onChange,
    required this.highlight,
    required this.onFocus,
    required this.onAdvanceCursor,
    required this.isFocused, 
    required this.puzzleCompleted,
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
    if (!widget.model.value.open) {
      return Container(
          decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: Colors.black,
      ));
    }

    // if (!justUpdated) {
    //   controller.text =
    //       widget.model.value.filled ? widget.model.value.value! : '';
    // } else {
    //   setState(() {
    //     // Only keep the user entered letter for one rebuild - server is source
    //     // of truth otherwise.
    //     justUpdated = false;
    //   });
    // }

    // Set cursor at end of current text.
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));

    if (widget.isFocused) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
    }

    final boxColour = _boxColour();

    // onChanged we want to :
    // - Get the latest value, and update the box so that it's only one
    //   upper-case letter (or blank).
    // - Send the update to the Stream with the remaining value.
    // - Tell the State that we've just updated. Otherwise, when the cell is
    // rebuilt immediately, the value will get overwritten by the server value.
    //
    // Using onChanged rather than the controller listener ensures we are only
    // notified about user changes here, and not our own network updates.
    final onUserChange = (String value) {
      _cutControllerToMaxOneLetter();

      setState(() {
        justUpdated = true;
      });

      // Update parent with state change...
      widget.onChange(controller.text);
      // ...but only advance cursor and remove focus from this node if there's
      // some content.
      if (controller.text.isNotEmpty) {
        widget.onAdvanceCursor();
      }
    };

    final cellTextField = TextField(
      autocorrect: false,
      controller: controller,
      onChanged: onUserChange,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 44, color: widget.puzzleCompleted ? Colors.green : Colors.black),
      onTap: widget.onFocus,
      focusNode: focusNode,
      // Have to add some padding because the TextField doesn't center properly?
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(top: 2.0, left: 2.0),
        isDense: true,
      ),
    );

    if (widget.model.number == null) {
      return _buildCell(cellTextField, boxColour);
    }

    return Stack(children: [
      // Without this fill, the bordered square shrinks for some reason...?
      Positioned.fill(child: _buildCell(cellTextField, boxColour)),
      Padding(
        padding: const EdgeInsets.only(left: 2.0),
        child: Text(
          '${widget.model.number}',
          style: TextStyle(fontSize: 9, color: Colors.black),
        ),
      ),
    ]);
  }

  Widget _buildCell(TextField cellTextField, Color boxColour) {
    return Container(
      decoration: BoxDecoration(
        border: _boxBorder(),
        color: boxColour,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          cellTextField,
        ],
      ),
    );
  }

  Color _boxColour() {
    if (widget.isFocused) {
      return Colors.blue.shade700;
    } else if (widget.highlight) {
      return Colors.blue.shade100;
    } else {
      return Colors.white;
    }
  }

  Border _boxBorder() {
    return Border(
      left: normalBorder,
      top: normalBorder,
      right: widget.model.isAcrossWordEnd ? thickBorder : normalBorder,
      bottom: widget.model.isDownWordEnd ? thickBorder : normalBorder,
    );
  }

  void _cutControllerToMaxOneLetter() {
    controller.value = controller.value.copyWith(
      text: controller.text.isEmpty
          ? ''
          : controller.text[controller.text.length - 1].toUpperCase(),
    );
    // Set cursor at end of current text.
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));
  }
}
