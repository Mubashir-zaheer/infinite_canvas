import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:random_color/random_color.dart';

class GeneratedNodes extends StatefulWidget {
  const GeneratedNodes({super.key});

  @override
  State<GeneratedNodes> createState() => _GeneratedNodesState();
}

class _GeneratedNodesState extends State<GeneratedNodes> {
  InfiniteCanvasController? controller;
  final gridSize = const Size.square(30);
  List<Offset> points = [];
  Color sketchColor = Colors.black;
  bool isFreeSketching = false;

  @override
  void initState() {
    super.initState();
    controller = InfiniteCanvasController();
    controller!.mouseDown = false;
  }

  void startFreeSketching(Color color) {
    setState(() {
      sketchColor = color;
      isFreeSketching = true; // Enable free sketching
      points.clear(); // Clear previous sketches if needed
    });
  }

  void stopFreeSketching() {
    setState(() {
      isFreeSketching = false; // Disable free sketching
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Canvas Example'),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          InfiniteCanvas(
            drawVisibleOnly: true,
            canAddEdges: true,
            controller: controller ??= InfiniteCanvasController(),
            gridSize: gridSize,

            menus: [
              MenuEntry(
                label: 'Create',
                menuChildren: [
                  MenuEntry(
                    label: 'Circle',
                    onPressed: () {
                      final color = RandomColor().randomColor();
                      final node = InfiniteCanvasNode(
                        key: UniqueKey(),
                        label: 'Node ${controller!.nodes.length}',
                        resizeMode: ResizeMode.cornersAndEdges,
                        offset: controller!.mousePosition,

                        size: Size(
                          Random().nextDouble() * 200 + 100,
                          Random().nextDouble() * 200 + 100,
                        ),
                        child: Builder(
                          builder: (context) {
                            return CustomPaint(
                              painter: InlineCustomPainter(
                                brush: Paint()..color = color,
                                builder: (brush, canvas, rect) {
      // Draw circle
                                  final diameter = min(rect.width, rect.height);
                                  final radius = diameter / 2;
                                  canvas.drawCircle(rect.center, radius, brush);
                                },
                              ),
                            );
                          },
                        ),
                      );
                      controller!.add(node);
                    },
                  ),
                  MenuEntry(
                    label: 'Triangle',
                    onPressed: () {
                      final color = RandomColor().randomColor();
                      final node = InfiniteCanvasNode(
                        key: UniqueKey(),
                        label: 'Node ${controller!.nodes.length}',
                        resizeMode: ResizeMode.cornersAndEdges,
                        offset: controller!.mousePosition,
                        size: Size(
                          Random().nextDouble() * 200 + 100,
                          Random().nextDouble() * 200 + 100,
                        ),
                        child: Builder(
                          builder: (context) {
                            return CustomPaint(
                              painter: InlineCustomPainter(
                                brush: Paint()..color = color,
                                builder: (brush, canvas, rect) {
      // Draw triangle
                                  final path = Path()
                                    ..moveTo(rect.left, rect.bottom)
                                    ..lineTo(rect.right, rect.bottom)
                                    ..lineTo(rect.center.dx, rect.top)
                                    ..close();
                                  canvas.drawPath(path, brush);
                                },
                              ),
                            );
                          },
                        ),
                      );
                      controller!.add(node);
                    },
                  ),
                  MenuEntry(
                    label: 'Rectangle',
                    onPressed: () {
                      final color = RandomColor().randomColor();
                      final node = InfiniteCanvasNode(
                        key: UniqueKey(),
                        label: 'Node ${controller!.nodes.length}',
                        resizeMode: ResizeMode.cornersAndEdges,
                        offset: controller!.mousePosition,
                        size: Size(
                          Random().nextDouble() * 200 + 100,
                          Random().nextDouble() * 200 + 100,
                        ),
                        child: Builder(
                          builder: (context) {
                            return CustomPaint(
                              painter: InlineCustomPainter(
                                brush: Paint()..color = color,
                                builder: (brush, canvas, rect) {
      // Draw rectangle
                                  canvas.drawRect(rect, brush);
                                },
                              ),
                            );
                          },
                        ),
                      );
                      controller!.add(node);
                    },
                  ),
                  MenuEntry(
                    label: 'Free Sketch ${controller!.nodes.length}',
                    onPressed: () {
                      // startFreeSketching(RandomColor().randomColor());
                      setState(() {
                        final color = RandomColor().randomColor();
                        final node = SketchNode(
                          color: color,
                          size:  Size(MediaQuery.of(context).size.width * 2, MediaQuery.of(context).size.height* 2) ,
                          offset: controller!.mousePosition,  // Use the current mouse position
                          points: [],

                        );
                        controller!.add(node);
                      });
                    },
                  ),
                  MenuEntry(
                    label: 'Text',
                    onPressed: () async {
                      final userText = await _getUserInputText(context);

                      if (userText != null && userText.isNotEmpty) {
                        final color = RandomColor().randomColor();

                        // Measure the text size
                        final textPainter = TextPainter(
                          text: TextSpan(
                            text: userText,
                            style: TextStyle(
                              color: color,
                              fontSize: 20,
                            ),
                          ),
                          textDirection: TextDirection.ltr,
                        );
                        textPainter.layout();

                        final textSize = textPainter.size;

                        final node = EditableTextNode(
                          offset: controller!.mousePosition,
                          size: textSize, // Set size based on measured text size
                          text: userText,
                          color: color,
                        );
                        controller!.add(node);
                      }
                    },
                  ),


                ],
              ),
              MenuEntry(
                label: 'Info',
                menuChildren: [
                  MenuEntry(
                    label: 'Cycle',
                    onPressed: () {
                      final fd = controller!.getDirectedGraph();
                      final messenger = ScaffoldMessenger.of(context);
                      final result = fd.cycle;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              'Cycle found: ${result.map((e) => e.key.toString()).join(', ')}'),
                        ),
                      );
                    },
                  ),
                  MenuEntry(
                    label: 'In Degree',
                    onPressed: () {
                      final fd = controller!.getDirectedGraph();
                      final result = fd.inDegreeMap;
      // Show dismissible dialog
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('In Degree'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final entry in result.entries.toList()
                                    ..sort(
                                          (a, b) => b.value.compareTo(a.value),
                                    ))
                                    Text(
                                      '${entry.key.id}: ${entry.value}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

        ],
      ),

    );
  }

  Future<String?> _getUserInputText(BuildContext context) async {
    String userInput = '';
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Text'),
          content: TextField(
            onChanged: (value) {
              userInput = value;
            },
            decoration: const InputDecoration(hintText: "Enter your text here"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(userInput);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class InlineCustomPainter extends CustomPainter {
  const InlineCustomPainter({
    required this.brush,
    required this.builder,
    this.isAntiAlias = true,
  });
  final Paint brush;
  final bool isAntiAlias;
  final void Function(Paint paint, Canvas canvas, Rect rect) builder;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    brush.isAntiAlias = isAntiAlias;
    canvas.save();
    builder(brush, canvas, rect);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Sketch Node to maintain the sketch state
class SketchNode extends InfiniteCanvasNode {
  final Color color;
  final List<Offset> points;

  SketchNode({
    required this.color,
    required Offset offset,
    required Size size,
    required this.points,
  }) : super(
    key: UniqueKey(),
    resizeMode: ResizeMode.disabled,

    offset: offset,
    size: size,
    child: FreeSketchWidget(color: color, points: points),
    allowMove: false
  );
}

class FreeSketchWidget extends StatefulWidget {
  final Color color;
  final List<Offset> points;

  const FreeSketchWidget({
    required this.color,
    required this.points,
    Key? key,
  }) : super(key: key);

  @override
  State<FreeSketchWidget> createState() => _FreeSketchWidgetState();
}

class _FreeSketchWidgetState extends State<FreeSketchWidget> {
  late List<Offset> points;

  @override
  void initState() {
    super.initState();
    points = widget.points;  // Initialize with passed points
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          points.add(localPosition);
        });
      },
      onPanEnd: (details) => points.add(Offset.zero),
      child: CustomPaint(
        painter: SketchPainter(points: points, color: Colors.black),
        child: Container(
          color: Colors.transparent,
          child:const Center(
            child: Text(
              'Draw here',
            ),
          )
        ),
      ),
    );
  }
}


class SketchPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  SketchPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


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
