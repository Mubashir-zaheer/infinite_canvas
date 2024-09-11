import 'dart:math';
import 'package:example/text_classes.dart';
import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:random_color/random_color.dart';

import 'free_sketch_classes.dart';


enum ShapeType { rectangle, circle, arrow, line, path }


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
  bool isDrawingLine = false; // Toggle for line drawing
  List<List<Offset>> shapes = [];
  List<Offset> currentShape = [];

  Offset? start; // Store the start position of the arrow

  @override
  void initState() {
    super.initState();
    controller = InfiniteCanvasController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Canvas Example'),
        centerTitle: false,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ShapeType.values.map((shapeType) {
            return IconButton(
              icon: Icon(_iconForShapeType(shapeType)),
              onPressed: () {
                setState(() {
                  // selectedShapeType = shapeType;
                  if (shapeType == ShapeType.circle) {
                    isFreeSketching = true;
                  } else {
                    isFreeSketching = false;
                  }

                });
              },
            );
          }).toList(),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (details) {
              if (isDrawingLine) {
                setState(() {
                  Offset tapPosition = details.localPosition;

                  // If the first point is close to the tap, close the shape
                  if (currentShape.isNotEmpty &&
                      (tapPosition - currentShape.first).distance < 20.0) {
                    currentShape.add(currentShape.first); // Close the loop
                    shapes.add(currentShape);
                    currentShape = []; // Start a new shape
                  } else {
                    currentShape.add(tapPosition);
                  }
                });
              }
            },
            child: CustomPaint(
              painter: LinePainter(shapes, currentShape),
              child: InfiniteCanvas(
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
                                      final diameter =
                                      min(rect.width, rect.height);
                                      final radius = diameter / 2;
                                      canvas.drawCircle(
                                          rect.center, radius, brush);
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
                          setState(() {
                            final color = RandomColor().randomColor();
                            final node = SketchNode(
                              color: color,
                              size: Size(
                                  MediaQuery.of(context).size.width * 10,
                                  MediaQuery.of(context).size.height * 10),
                              offset: controller!.mousePosition,
                              points: [],
                            );
                            controller!.add(node);
                          });
                        },
                      ),
                      MenuEntry(
                        label: 'Draw Lines',
                        onPressed: () {
                          setState(() {
                            isDrawingLine = true; // Activate line drawing
                          });
                        },
                      ),
                      MenuEntry(
                        label: 'Text',
                        onPressed: () async {
                          final userText = await _getUserInputText(context);

                          if (userText != null && userText.isNotEmpty) {
                            final color = RandomColor().randomColor();

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
                              size: textSize,
                              text: userText,
                              color: color,
                            );
                            controller!.add(node);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            shapes.clear(); // Clear all shapes to reset the drawing
            currentShape.clear();
            isDrawingLine = false; // Stop line drawing mode
          });
        },
        child: const Icon(Icons.refresh),
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
  IconData _iconForShapeType(ShapeType shapeType) {
    switch (shapeType) {
      case ShapeType.rectangle:
        return Icons.crop_square; // Rectangle
      case ShapeType.circle:
        return Icons.circle; // Circle
      case ShapeType.arrow:
        return Icons.arrow_forward; // Arrow
      case ShapeType.line:
        return Icons.create; // Freehand line
      case ShapeType.path:
        return Icons.timeline; // New icon for "Path"
      default:
        return Icons.help;
    }
  }
}


// Custom painter for drawing lines
class LinePainter extends CustomPainter {
  final List<List<Offset>> shapes;
  final List<Offset> currentShape;

  LinePainter(this.shapes, this.currentShape);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    var pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Draw all completed shapes
    for (var shape in shapes) {
      for (int i = 0; i < shape.length - 1; i++) {
        canvas.drawLine(shape[i], shape[i + 1], paint);
      }
    }

    // Draw the current shape being drawn
    for (int i = 0; i < currentShape.length - 1; i++) {
      canvas.drawLine(currentShape[i], currentShape[i + 1], paint);
    }

    // Draw the first point of the current shape if it exists
    if (currentShape.isNotEmpty) {
      canvas.drawCircle(currentShape.first, 6.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
