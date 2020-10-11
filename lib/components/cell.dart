import 'package:csolve/crossword_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Cell extends StatefulWidget {
  final int number;
  final Value value;
  final Function(String) onChange;
  final bool highlight;
  final Function() onFocus;
  Cell({
    Key key,
    @required this.number,
    @required this.value,
    @required this.onChange,
    @required this.highlight,
    @required this.onFocus,
  }) : super(key: key);

  @override
  _CellState createState() => _CellState();
}

class _CellState extends State<Cell> {
  FocusNode _focus = new FocusNode();

  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focus.hasFocus) {
      widget.onFocus();
    }
  }

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
      widget.onChange(controller.text);
    };

    final t = TextField(
      autocorrect: false,
      focusNode: _focus,
      controller: controller,
      onChanged: userChanged,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.black),
    );

    final square = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: boxColour,
      ),
      child: Center(child: t),
    );

    if (widget.number != null) {
      return Stack(children: [square, Text('${widget.number}')]);
    } else {
      return square;
    }
  }
}
