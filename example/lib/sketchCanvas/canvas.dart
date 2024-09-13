import 'package:flutter/material.dart';
import 'dart:math' as math; // Import the math library
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
  Offset? lastTap; // Store the last tap position to draw a dot

  double gridSize = 20.0; // Size of the grid
  // Method to snap the tap/drag position to the nearest grid intersection
  Offset _getSnappedPosition(Offset position) {
    double snappedX = (position.dx / gridSize).round() * gridSize;
    double snappedY = (position.dy / gridSize).round() * gridSize;
    return Offset(snappedX, snappedY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw Shapes and Freehand with Grid')),
      body: GestureDetector(
        onTapUp: (details) {
          if (selectedShapeType != ShapeType.path) {
            switch (selectedShapeType) {
              case ShapeType.autoSquare:
                setState(() {
                  Offset tappedPoint = _getSnappedPosition(details.localPosition);

                  // If there's no shape, start a new one
                  if (currentShape == null) {
                    currentShape = LinearLinePainter(tappedPoint);
                    lastTap = tappedPoint; // Store the first tap point
                  }
                  // If the shape is a LinearLinePainter and it's not closed yet
                  else if (currentShape is LinearLinePainter) {
                    LinearLinePainter linePainter = currentShape as LinearLinePainter;

                    // Check if the tapped point is near the first point (within a certain distance, e.g. 20 pixels)
                    if (linePainter.points.isNotEmpty &&
                        (tappedPoint - linePainter.points.first).distance < 20.0) {

                      // Close the shape by adding the first point as the last point
                      linePainter.addPoint(linePainter.points.first);

                      // Save the closed shape and reset to start a new one
                      shapes.add(linePainter);
                      currentShape = null;  // Set to null so a new shape can start on the next tap
                      lastTap = null; // Remove the last tap since the shape is complete
                    } else {
                      // Add the tapped point to the current shape
                      linePainter.addPoint(tappedPoint);
                      lastTap = tappedPoint; // Update last tap point for the next line
                    }
                  }
                });
                break;
              default:
                break;
            }
          }
          if (isDrawingLine) {
            setState(() {
              Offset tapPosition = details.localPosition;

              // If the first point is close to the tap, close the shape
              if (currentFreehandShape.isNotEmpty &&
                  (tapPosition - currentFreehandShape.first).distance < 20.0) {
                currentFreehandShape
                    .add(currentFreehandShape.first); // Close the loop
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
            if (selectedShapeType == ShapeType.path ||
                selectedShapeType == ShapeType.line) {
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
            if (selectedShapeType == ShapeType.path ||
                selectedShapeType == ShapeType.line) {
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
          painter: GridPainter(
              shapes, freehandShapes, currentShape, currentFreehandShape,gridSize,lastTap,),
          child: Container(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            shapes.clear();
            freehandShapes.clear();
            currentShape = null;
            currentFreehandShape.clear();
          });
        },
        child: Icon(Icons.refresh),
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
                  print("shapeType: $shapeType");
                  if (ShapeType.path == shapeType) {
                    print("shapeType");
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
      case ShapeType.autoSquare:
        return Icons.crop_7_5;
      default:
        return Icons.help;
    }
  }
}

enum ShapeType { rectangle, circle, arrow, line, path, autoSquare }

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

    final arrowHeadPoint1 = currentPoint -
        Offset.fromDirection(direction - arrowHeadAngle, arrowHeadSize);
    final arrowHeadPoint2 = currentPoint -
        Offset.fromDirection(direction + arrowHeadAngle, arrowHeadSize);

    canvas.drawLine(currentPoint, arrowHeadPoint1, arrowPaint);
    canvas.drawLine(currentPoint, arrowHeadPoint2, arrowPaint);
  }
}



class LinearLinePainter extends Shape {
  List<Offset> points = [];
  bool isClosed = false; // Indicates if the shape is closed
  final double distanceFromInnerShape = 40.0; // Distance between the inner and outer shapes

  LinearLinePainter(Offset start) : super(start) {
    points.add(start); // Initialize with the first point
  }

  // Add a new point to the list of points
  void addPoint(Offset point) {
    if (points.isNotEmpty && (point - points.first).distance < 20.0) {
      // Close the shape if the new point is near the first point
      points.add(points.first); // Close the shape by connecting to the first point
      isClosed = true;          // Mark the shape as closed
    } else {
      points.add(point); // Add the new point to the shape
    }
  }

  @override
  void draw(Canvas canvas, Paint paint) {
    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw the original shape
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    // If the shape is closed, draw the outer version and connect the corners
    if (isClosed) {
      _drawOuterShape(canvas, linePaint);
      _connectCorners(canvas, linePaint);
    }
  }

  // Method to draw the outer shape by scaling the points based on bounding box
  void _drawOuterShape(Canvas canvas, Paint paint) {
    if (points.length < 2) return;

    // Calculate the bounding box for the shape
    double minX = points[0].dx;
    double minY = points[0].dy;
    double maxX = points[0].dx;
    double maxY = points[0].dy;

    for (var point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }

    // Calculate the center of the bounding box (centroid)
    Offset centroid = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    // Calculate the outward movement for the outer shape based on the bounding box
    double width = maxX - minX;
    double height = maxY - minY;
    double scaleFactor = (distanceFromInnerShape / math.min(width, height)) + 1;

    // Move each point outward proportionally based on the bounding box
    List<Offset> outerPoints = points.map((point) {
      double deltaX = point.dx - centroid.dx;
      double deltaY = point.dy - centroid.dy;

      return Offset(
        centroid.dx + deltaX * scaleFactor,
        centroid.dy + deltaY * scaleFactor,
      );
    }).toList();

    // Draw the outer shape by connecting the scaled points
    for (int i = 0; i < outerPoints.length - 1; i++) {
      canvas.drawLine(outerPoints[i], outerPoints[i + 1], paint);
    }
    // Close the shape
    canvas.drawLine(outerPoints.last, outerPoints.first, paint);
  }

  // Method to connect corresponding corners of the inner and outer shapes
  void _connectCorners(Canvas canvas, Paint paint) {
    if (points.length < 2) return;

    // Calculate the bounding box for the shape
    double minX = points[0].dx;
    double minY = points[0].dy;
    double maxX = points[0].dx;
    double maxY = points[0].dy;

    for (var point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }

    // Calculate the center of the bounding box (centroid)
    Offset centroid = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    double width = maxX - minX;
    double height = maxY - minY;
    double scaleFactor = (distanceFromInnerShape / math.min(width, height)) + 1;

    List<Offset> outerPoints = points.map((point) {
      double deltaX = point.dx - centroid.dx;
      double deltaY = point.dy - centroid.dy;

      return Offset(
        centroid.dx + deltaX * scaleFactor,
        centroid.dy + deltaY * scaleFactor,
      );
    }).toList();

    // Connect corresponding corners between inner and outer shapes
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], outerPoints[i], paint);
    }
  }

  @override
  void update(Offset position) {
    currentPoint = position;
    points.add(currentPoint); // Add the point while drawing
  }
}







class GridPainter extends CustomPainter {
  final List<Shape> shapes;
  final List<List<Offset>> freehandShapes;
  final Shape? currentShape;
  final List<Offset> currentFreehandShape;
  final double gridSize;
  final Offset? lastTap; // Nullable Offset for the temporary dot

  GridPainter(this.shapes, this.freehandShapes, this.currentShape, this.currentFreehandShape, this.gridSize, this.lastTap);

  @override
  void paint(Canvas canvas, Size size) {
    var gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.0;

    // Draw grid
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

    // Draw the current shape being drawn
    if (currentShape != null) {
      currentShape!.draw(canvas, shapePaint);
    }

    // Ensure lastTap is not null before drawing the dot
    if (lastTap != null) {
      var dotPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      // Use lastTap as the center and 5.0 as the radius
      canvas.drawCircle(lastTap!, 5.0, dotPaint); // Ensure the radius is a double (5.0)
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

