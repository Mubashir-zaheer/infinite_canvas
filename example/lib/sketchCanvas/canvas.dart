import 'package:flutter/material.dart';

class DrawShapeScreen extends StatefulWidget {
  @override
  _DrawShapeScreenState createState() => _DrawShapeScreenState();
}

class _DrawShapeScreenState extends State<DrawShapeScreen> {
  List<Shape> shapes = [];
  List<List<Offset>> freehandShapes = [];
  List<Offset> currentFreehandShape = [];
  Path currentPath = Path();
  Shape? currentShape;
  ShapeType selectedShapeType = ShapeType.line; // Default shape type
  bool isDrawingLine = false;

List<Shape> redoList = [];


  bool isPickingPoints = false;
  Offset? pointA;
  Offset? pointB;
  String? measurement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sketch Canvas'),

      actions: [
        IconButton(
          icon: Icon(Icons.undo),
          onPressed: () {
            // Undo the last action
            setState(() {
              if (shapes.isNotEmpty) {
                redoList.add(shapes.removeLast());
              }
            });
          },
        ),
      ],
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.redo),
          onPressed: () {
            shapes.add(redoList.removeLast());
          },
      ),
      ),
      body: GestureDetector(
        onTapUp: (details)async {
          if (selectedShapeType == ShapeType.text) {
            // setState(() async{
              // Show dialog to get user input text
              String? userText = await getUserInputText(context);
              if (userText != null && userText.isNotEmpty) {
                // Create a TextShape with user input
                currentShape = TextShape(details.localPosition, userText);
                shapes.add(currentShape!);
                currentShape = null;
              }
              setState(() {

              });
            // });

          } else if (selectedShapeType == ShapeType.measurementLine) {
            if (pointA == null) {
              pointA = details.localPosition;
              isPickingPoints = true;
            } else if (pointB == null) {
              pointB = details.localPosition;
              isPickingPoints = false;
              // Open dialog for inputting the distance
              _showMeasurementDialog();
            }
          } else if (isDrawingLine) {
            setState(() {
              Offset tapPosition = details.localPosition;
              // If the first point is close to the tap, close the shape
              if (currentFreehandShape.isNotEmpty &&
                  (tapPosition - currentFreehandShape.first).distance < 20.0) {
                currentFreehandShape.add(currentFreehandShape.first); // Close the loop
                freehandShapes.add(currentFreehandShape);
                currentFreehandShape = []; // Start a new shape
              } else {
                currentFreehandShape.add(tapPosition);
              }
            });
          }
        },
        onPanUpdate: (details) {
          setState(() {
            if (selectedShapeType == ShapeType.path || selectedShapeType == ShapeType.line) {
              if (currentFreehandShape.isEmpty) {
                currentFreehandShape.add(details.localPosition);
              } else {
                currentFreehandShape.add(details.localPosition);
              }
            } else if (currentShape != null) {
              currentShape!.update(details.localPosition);
            }
          });
        },
        onPanEnd: (details) {
          setState(() {
            if (selectedShapeType == ShapeType.path || selectedShapeType == ShapeType.line) {
              if (currentFreehandShape.isNotEmpty) {
                freehandShapes.add(currentFreehandShape);
                currentFreehandShape = [];
              }
            } else if (currentShape != null) {
              currentShape!.complete();
              shapes.add(currentShape!);
              currentShape = null;
            }
          });
        },
        onTapDown: (details) {
          setState(() {
            if (selectedShapeType != ShapeType.path) {
              switch (selectedShapeType) {
                case ShapeType.rectangle:
                  currentShape = RectangleShape(details.localPosition);
                  break;
                case ShapeType.circle:
                  currentShape = CircleShape(details.localPosition);
                  break;
                case ShapeType.arrow:
                  currentShape = ArrowShape(details.localPosition);
                  break;
                default:
                  break;
              }
            }
          });
        },
        child: CustomPaint(
          painter: GridPainter(shapes, freehandShapes, currentShape, currentFreehandShape),
          child: Container(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            redoList.clear();
            shapes.clear();
            freehandShapes.clear();
            currentShape = null;
            currentFreehandShape.clear();
          });
        },
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ShapeType.values.map((shapeType) {
            return IconButton(
              icon: Icon(_iconForShapeType(shapeType)),
              onPressed: () {
                setState(() {
                  selectedShapeType = shapeType;
                  if(ShapeType.path == shapeType){
                    print("path");
                    isDrawingLine = true;
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
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
      case ShapeType.measurementLine:
        return Icons.straighten; // New icon for "Measurement Line"
      case ShapeType.text:
        return Icons.text_fields; // New icon for "Measurement Line"
      default:
        return Icons.help;
    }
  }

  void _showMeasurementDialog() async {
    String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        String input = '';
        return AlertDialog(
          title: Text('Enter Distance'),
          content: TextField(
            onChanged: (value) {
              input = value;
            },
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter distance in meters"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(input);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        measurement = result;
        // Save the shape (line with distance)
        shapes.add(MeasurementLine(pointA!, pointB!, measurement!));
        pointA = null;
        pointB = null;
      });
    }
  }
  Future<String?> getUserInputText(BuildContext context) async {
    String userInput = '';
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Text'),
          content: TextField(
            onChanged: (value) {
              userInput = value;
            },
            decoration: const InputDecoration(),
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

enum ShapeType { rectangle, circle, arrow, line, path , measurementLine, text}

abstract class Shape {
  Offset start;
  late Offset currentPoint;

  Shape(this.start) {
    currentPoint = start;
  }

  void update(Offset position) {
    currentPoint = position;
  }

  void complete() {}

  void draw(Canvas canvas, Paint paint);
}

class RectangleShape extends Shape {
  RectangleShape(Offset start) : super(start);

  @override
  void draw(Canvas canvas, Paint paint) {
    final rect = Rect.fromPoints(start, currentPoint);
    canvas.drawRect(rect, paint);
  }
}

class CircleShape extends Shape {
  CircleShape(Offset start) : super(start);

  @override
  void draw(Canvas canvas, Paint paint) {
    final radius = (start - currentPoint).distance;
    canvas.drawCircle(start, radius, paint);
  }
}

class ArrowShape extends Shape {
  ArrowShape(Offset start) : super(start);

  @override
  void draw(Canvas canvas, Paint paint) {
    final arrowPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, currentPoint, arrowPaint);

    const arrowHeadSize = 10.0;
    final direction = (currentPoint - start).direction;
    const arrowHeadAngle = 0.5;

    final arrowHeadPoint1 = currentPoint - Offset.fromDirection(direction - arrowHeadAngle, arrowHeadSize);
    final arrowHeadPoint2 = currentPoint - Offset.fromDirection(direction + arrowHeadAngle, arrowHeadSize);

    canvas.drawLine(currentPoint, arrowHeadPoint1, arrowPaint);
    canvas.drawLine(currentPoint, arrowHeadPoint2, arrowPaint);
  }
}

class GridPainter extends CustomPainter {
  final List<Shape> shapes;
  final List<List<Offset>> freehandShapes;
  final Shape? currentShape;
  final List<Offset> currentFreehandShape;

  GridPainter(this.shapes, this.freehandShapes, this.currentShape, this.currentFreehandShape);

  @override
  void paint(Canvas canvas, Size size) {
    var gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.0;

    // Draw grid
    double gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw all completed shapes
    var shapePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (var shape in shapes) {
      shape.draw(canvas, shapePaint);
    }

    // Draw all freehand shapes
    for (var shape in freehandShapes) {
      for (int i = 0; i < shape.length - 1; i++) {
        canvas.drawLine(shape[i], shape[i + 1], shapePaint);
      }
    }

    // Draw the current shape being drawn
    if (currentShape != null) {
      shapePaint.color = Colors.blue; // Highlight color
      currentShape!.draw(canvas, shapePaint);
    }

    // Draw the current freehand shape being drawn
    if (currentFreehandShape.isNotEmpty) {
      for (int i = 0; i < currentFreehandShape.length - 1; i++) {
        canvas.drawLine(currentFreehandShape[i], currentFreehandShape[i + 1], shapePaint);
      }
    }

    // Draw the first point of the current shape if it exists
    if (currentShape != null && currentShape!.start != currentShape!.currentPoint) {
      canvas.drawCircle(currentShape!.start, 6.0, shapePaint..color = Colors.red);
    }


    var paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    var pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;


    for (var shape in freehandShapes) {
      for (int i = 0; i < shape.length - 1; i++) {
        canvas.drawLine(shape[i], shape[i + 1], paint);
      }
    }

    // Draw the current shape being drawn
    for (int i = 0; i < currentFreehandShape.length - 1; i++) {
      canvas.drawLine(currentFreehandShape[i], currentFreehandShape[i + 1], paint);
    }

    // Draw the first point of the current shape if it exists
    if (currentFreehandShape.isNotEmpty) {
      canvas.drawCircle(currentFreehandShape.first, 6.0, pointPaint);
    }


  }



  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MeasurementLine extends Shape {
  final Offset end;
  final String distance;

  MeasurementLine  (Offset start, this.end, this.distance) : super(start);

  @override
  void draw(Canvas canvas, Paint paint) {
    // Draw the line
    canvas.drawLine(start, end, paint);
    _drawEndMarkers(canvas, start, end, paint);
    // Draw the measurement text
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: distance, style: const TextStyle(color: Colors.black, fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    // Calculate the mid-point of the line to position the text
    Offset midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    textPainter.paint(canvas, midPoint);
  }

  void _drawEndMarkers(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Calculate the direction vector of the line
    final direction = (end - start).direction;

    // Calculate the perpendicular direction (90 degrees)
    final perpendicularDirection = direction + 1.5708; // 1.5708 radians = 90 degrees

    // Define the size of the end markers
    const markerLength = 10.0;

    // Draw marker at start
    final startMarker1 = start + Offset.fromDirection(perpendicularDirection, markerLength);
    final startMarker2 = start - Offset.fromDirection(perpendicularDirection, markerLength);
    canvas.drawLine(startMarker1, startMarker2, paint);

    // Draw marker at end
    final endMarker1 = end + Offset.fromDirection(perpendicularDirection, markerLength);
    final endMarker2 = end - Offset.fromDirection(perpendicularDirection, markerLength);
    canvas.drawLine(endMarker1, endMarker2, paint);
  }
}

class TextShape extends Shape {
  final String text;

  TextShape(Offset start, this.text) : super(start);

  @override
  void draw(Canvas canvas, Paint paint) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.black, fontSize: 24)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, start);
  }
}





