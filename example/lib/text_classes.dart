import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';

class EditableTextNode extends InfiniteCanvasNode {
  EditableTextNode({
    required Offset offset,
    required Size size,
    required String text,
    required Color color,
  }) : super(
    key: UniqueKey(),
    resizeMode: ResizeMode.disabled,
    offset: offset,
    size: size,
    child: EditableTextWidget(
      initialText: text,
      textColor: color,
    ),
  );

}

class EditableTextWidget extends StatefulWidget {
  final String initialText;
  final Color textColor;

  const EditableTextWidget({
    required this.initialText,
    required this.textColor,
    Key? key,
  }) : super(key: key);

  @override
  _EditableTextWidgetState createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditableText(
      controller: _controller,
      focusNode: FocusNode(),
      style: TextStyle(
        color: widget.textColor,
        fontSize: 20,
      ),
      cursorColor: widget.textColor,
      backgroundCursorColor: Colors.grey,
      onChanged: (newValue) {
        setState(() {
          print(newValue);
          // Update the widget state or do something with the new text
        });
      },
    );
  }
}
