import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(MaterialApp(
    home: DrawShapeScreen(),
  ));
}

class DrawShapeScreen extends StatefulWidget {
  @override
  _DrawShapeScreenState createState() => _DrawShapeScreenState();
}

class _DrawShapeScreenState extends State<DrawShapeScreen> {
  List<Shape> shapes = [];
  Shape? currentShape;
  ShapeType selectedShapeType = ShapeType.line; // Default shape type
  bool isDrawingLine = false;
  Offset? lastTap; // Store the last tap position to draw a dot

  double gridSize = 20.0; // Size of the grid

  // Variables for moving shapes
  Shape? selectedShape;
  Offset? previousPanPosition;

  // Selection mode
  bool isSelectionMode = false;

  double shapeScale = 1.0; // Scale factor for the selected shape

  // Rotation variables
  double initialRotation = 0.0;
  double currentRotation = 0.0;

  // For handling scale and pan
  Offset? initialFocalPoint;
  double initialScale = 1.0;

  // Method to snap the tap/drag position to the nearest grid intersection
  Offset _getSnappedPosition(Offset position) {
    double snappedX = (position.dx / gridSize).round() * gridSize;
    double snappedY = (position.dy / gridSize).round() * gridSize;
    return Offset(snappedX, snappedY);
  }

  // Method to get the shape at a given position
  Shape? _getShapeAtPosition(Offset position) {
    for (final shape in shapes.reversed) {
      if (shape.contains(position)) {
        return shape;
      }
    }
    return null;
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      selectedShape = null;
      shapeScale = 1.0; // Reset the shapeScale when toggling selection mode
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Shapes and Freehand with Grid'),
        actions: [
          IconButton(
            icon: Icon(isSelectionMode ? Icons.edit : Icons.select_all),
            onPressed: _toggleSelectionMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (details) {
              if (isSelectionMode) {
                setState(() {
                  selectedShape = _getShapeAtPosition(details.localPosition);
                  if (selectedShape is ScalableShape) {
                    shapeScale = (selectedShape as ScalableShape).scaleFactor;
                  } else {
                    shapeScale = 1.0; // Reset the shapeScale
                  }
                });
              } else {
                if (selectedShapeType == ShapeType.autoSquare) {
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

                      // Check if the tapped point is near the first point
                      if (linePainter.points.isNotEmpty &&
                          (tappedPoint - linePainter.points.first).distance < 20.0) {
                        // Close the shape by adding the first point as the last point
                        linePainter.addPoint(linePainter.points.first);

                        // Save the closed shape and reset to start a new one
                        shapes.add(linePainter);
                        currentShape = null; // Set to null so a new shape can start on the next tap
                        lastTap = null; // Remove the last tap since the shape is complete
                      } else {
                        // Add the tapped point to the current shape
                        linePainter.addPoint(tappedPoint);
                        lastTap = tappedPoint; // Update last tap point for the next line
                      }
                    }
                  });
                }
              }
            },
            child: Listener(
              onPointerDown: (event) {
                // Needed to capture pointer events for gestures
              },
              child: CustomPaint(
                painter: GridPainter(
                  shapes,
                  currentShape,
                  gridSize,
                  lastTap,
                  selectedShape, // Pass the selectedShape to the painter
                ),
                child: Container(),
              ),
            ),
            // Handle both pan and scale in onScale callbacks
            onScaleStart: (details) {
              if (isSelectionMode) {
                selectedShape ??= _getShapeAtPosition(details.localFocalPoint);
                if (selectedShape != null) {
                  if (selectedShape is ScalableShape) {
                    shapeScale = (selectedShape as ScalableShape).scaleFactor;
                  } else {
                    shapeScale = 1.0; // Reset the shapeScale
                  }
                  initialRotation = selectedShape!.rotation;
                  previousPanPosition = details.localFocalPoint;
                  initialFocalPoint = details.localFocalPoint;
                  initialScale = shapeScale;
                  // Bring the selected shape to the front
                  shapes.remove(selectedShape);
                  shapes.add(selectedShape!);
                }
              } else {
                if (selectedShapeType == ShapeType.line ||
                    selectedShapeType == ShapeType.path) {
                  currentShape = FreehandShape(details.localFocalPoint);
                } else if (selectedShapeType != ShapeType.autoSquare) {
                  switch (selectedShapeType) {
                    case ShapeType.rectangle:
                      currentShape = RectangleShape(details.localFocalPoint);
                      break;
                    case ShapeType.circle:
                      currentShape = CircleShape(details.localFocalPoint);
                      break;
                    case ShapeType.arrow:
                      currentShape = ArrowShape(details.localFocalPoint);
                      break;
                    default:
                      break;
                  }
                }
              }
            },
            onScaleUpdate: (details) {
              if (isSelectionMode && selectedShape != null) {
                setState(() {
                  if (details.pointerCount == 1) {
                    // Single finger gestures - Pan
                    if (previousPanPosition != null) {
                      Offset delta = details.localFocalPoint - previousPanPosition!;
                      selectedShape!.translate(delta);
                      previousPanPosition = details.localFocalPoint;
                    }
                  } else if (details.pointerCount > 1) {
                    // Multi-finger gestures - Scale and Rotate
                    if (selectedShape is ScalableShape) {
                      shapeScale = (initialScale * details.scale).clamp(0.5, 2.0);
                      (selectedShape as ScalableShape).scale(shapeScale);
                    }
                    selectedShape!.rotation = initialRotation + details.rotation;
                  }
                });
              } else {
                setState(() {
                  if (currentShape != null &&
                      (selectedShapeType == ShapeType.line ||
                          selectedShapeType == ShapeType.path)) {
                    currentShape!.update(details.localFocalPoint);
                  } else if (currentShape != null &&
                      selectedShapeType != ShapeType.autoSquare) {
                    currentShape!.update(details.localFocalPoint);
                  }
                });
              }
            },
            onScaleEnd: (details) {
              if (isSelectionMode) {
                previousPanPosition = null;
                initialFocalPoint = null;
                initialScale = 1.0;
                initialRotation = 0.0;
              } else {
                if (currentShape != null &&
                    (selectedShapeType == ShapeType.line ||
                        selectedShapeType == ShapeType.path)) {
                  shapes.add(currentShape!);
                  currentShape = null;
                } else if (currentShape != null &&
                    selectedShapeType != ShapeType.autoSquare) {
                  currentShape!.complete();
                  shapes.add(currentShape!);
                  currentShape = null;
                }
              }
            },
          ),
          // if (selectedShape != null && selectedShape is ScalableShape)
          //   Positioned(
          //     bottom: 0,
          //     left: 0,
          //     right: 0,
          //     child: Container(
          //       color: Colors.white.withOpacity(0.8),
          //       child: Slider(
          //         value: shapeScale,
          //         min: 0.5,
          //         max: 2.0,
          //         divisions: 100,
          //         label: shapeScale.toStringAsFixed(2),
          //         onChanged: (value) {
          //           setState(() {
          //             shapeScale = value;
          //             (selectedShape as ScalableShape).scale(value);
          //           });
          //         },
          //       ),
          //     ),
          //   ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            shapes.clear();
            currentShape = null;
            selectedShape = null;
            shapeScale = 1.0; // Reset the shapeScale when clearing
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
                  if (ShapeType.path == shapeType || ShapeType.line == shapeType) {
                    isDrawingLine = true;
                  } else {
                    isDrawingLine = false;
                  }
                  // Exit selection mode when changing shape type
                  isSelectionMode = false;
                  selectedShape = null;
                  shapeScale = 1.0; // Reset the shapeScale
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

// Base class for shapes
abstract class Shape {
  Offset start;
  Offset currentPoint;
  double rotation = 0.0; // Rotation angle in radians

  Shape(this.start) : currentPoint = start;

  void update(Offset position) {
    currentPoint = position;
  }

  void complete() {}

  void draw(Canvas canvas, Paint paint, {bool isSelected = false});

  bool contains(Offset point);

  void translate(Offset offset);
}

// Mixin for scalable shapes
mixin ScalableShape on Shape {
  double scaleFactor = 1.0;

  void scale(double newScaleFactor);
}

class RectangleShape extends Shape with ScalableShape {
  RectangleShape(Offset start) : super(start);

  @override
  void scale(double newScaleFactor) {
    scaleFactor = newScaleFactor;
  }

  @override
  void draw(Canvas canvas, Paint paint, {bool isSelected = false}) {
    final rect = Rect.fromPoints(start, currentPoint);
    Offset center = rect.center;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(scaleFactor);

    Rect transformedRect = Rect.fromCenter(
        center: Offset(0, 0), width: rect.width, height: rect.height);

    Paint finalPaint = isSelected
        ? (Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke)
        : paint;

    canvas.drawRect(transformedRect, finalPaint);
    canvas.restore();
  }

  @override
  bool contains(Offset point) {
    final rect = Rect.fromPoints(start, currentPoint).inflate(10);
    Offset center = rect.center;

    // Transform point to shape's coordinate system
    Offset transformedPoint = _rotatePoint(point, center, -rotation);
    transformedPoint = (transformedPoint - center) / scaleFactor + center;

    return rect.contains(transformedPoint);
  }

  @override
  void translate(Offset offset) {
    start += offset;
    currentPoint += offset;
  }
}

class CircleShape extends Shape with ScalableShape {
  CircleShape(Offset start) : super(start);

  @override
  void scale(double newScaleFactor) {
    scaleFactor = newScaleFactor;
  }

  @override
  void draw(Canvas canvas, Paint paint, {bool isSelected = false}) {
    double radius = (start - currentPoint).distance * scaleFactor;
    Offset center = start;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    Paint finalPaint = isSelected
        ? (Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke)
        : paint;

    canvas.drawCircle(Offset(0, 0), radius, finalPaint);
    canvas.restore();
  }

  @override
  bool contains(Offset point) {
    double radius = (start - currentPoint).distance * scaleFactor + 10;
    Offset center = start;

    // Transform point to shape's coordinate system
    Offset transformedPoint = _rotatePoint(point, center, -rotation);

    return (transformedPoint - center).distance <= radius;
  }

  @override
  void translate(Offset offset) {
    start += offset;
    currentPoint += offset;
  }
}

class ArrowShape extends Shape with ScalableShape {
  ArrowShape(Offset start) : super(start);

  @override
  void scale(double newScaleFactor) {
    scaleFactor = newScaleFactor;
  }

  @override
  void draw(Canvas canvas, Paint paint, {bool isSelected = false}) {
    final arrowPaint = Paint()
      ..color = isSelected ? Colors.blueAccent : paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset center = start;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Calculate scaled points
    Offset scaledCurrentPoint = (currentPoint - start) * scaleFactor;

    canvas.drawLine(Offset(0, 0), scaledCurrentPoint, arrowPaint);

    const arrowHeadSize = 10.0;
    final direction = (scaledCurrentPoint).direction;
    const arrowHeadAngle = 0.5;

    final arrowHeadPoint1 = scaledCurrentPoint -
        Offset.fromDirection(direction - arrowHeadAngle, arrowHeadSize);
    final arrowHeadPoint2 = scaledCurrentPoint -
        Offset.fromDirection(direction + arrowHeadAngle, arrowHeadSize);

    canvas.drawLine(scaledCurrentPoint, arrowHeadPoint1, arrowPaint);
    canvas.drawLine(scaledCurrentPoint, arrowHeadPoint2, arrowPaint);

    canvas.restore();
  }

  @override
  bool contains(Offset point) {
    // Transform point to shape's coordinate system
    Offset transformedPoint = _rotatePoint(point, start, -rotation);

    // Calculate scaled current point
    Offset scaledCurrentPoint = start + (currentPoint - start) * scaleFactor;

    double distance = _distanceFromPointToLineSegment(
        start, scaledCurrentPoint, transformedPoint);
    return distance <= 20.0; // Increased threshold for easier selection
  }

  @override
  void translate(Offset offset) {
    start += offset;
    currentPoint += offset;
  }
}

class FreehandShape extends Shape {
  List<Offset> points = [];

  FreehandShape(Offset start) : super(start) {
    points.add(start);
  }

  @override
  void draw(Canvas canvas, Paint paint, {bool isSelected = false}) {
    Paint freehandPaint = Paint()
      ..color = isSelected ? Colors.blueAccent : paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Path path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, freehandPaint);
    }
  }

  @override
  bool contains(Offset point) {
    // Check if the point is close to any segment of the freehand drawing
    for (int i = 0; i < points.length - 1; i++) {
      double distance =
      _distanceFromPointToLineSegment(points[i], points[i + 1], point);
      if (distance <= 20.0) {
        // Adjust threshold for selection sensitivity
        return true;
      }
    }
    return false;
  }

  @override
  void translate(Offset offset) {
    for (int i = 0; i < points.length; i++) {
      points[i] += offset;
    }
  }

  @override
  void update(Offset position) {
    points.add(position);
  }
}

class LinearLinePainter extends Shape with ScalableShape {
  List<Offset> points = [];
  List<Offset> originalPoints = [];
  bool isClosed = false; // Indicates if the shape is closed
  final double distanceFromInnerShape =
  40.0; // Distance between the inner and outer shapes

  LinearLinePainter(Offset start) : super(start) {
    points.add(start); // Initialize with the first point
    originalPoints.add(start);
  }

  // Add a new point to the list of points
  void addPoint(Offset point) {
    if (points.isNotEmpty && (point - points.first).distance < 20.0) {
      // Close the shape if the new point is near the first point
      points.add(points.first); // Close the shape by connecting to the first point
      originalPoints.add(originalPoints.first);
      isClosed = true; // Mark the shape as closed
    } else {
      points.add(point); // Add the new point to the shape
      originalPoints.add(point);
    }
  }

  @override
  void scale(double newScaleFactor) {
    // Update the scale factor
    scaleFactor = newScaleFactor;

    // Calculate the centroid of the original points
    Offset centroid = _calculateCentroid(originalPoints);

    // Scale the points from the original points
    points = originalPoints.map((point) {
      return centroid + (point - centroid) * scaleFactor;
    }).toList();
  }

  Offset _calculateCentroid(List<Offset> points) {
    double sumX = 0;
    double sumY = 0;
    for (var point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / points.length, sumY / points.length);
  }

  @override
  void draw(Canvas canvas, Paint paint, {bool isSelected = false}) {
    final linePaint = Paint()
      ..color = isSelected ? Colors.blueAccent : Colors.red
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate centroid
    Offset centroid = _calculateCentroid(points);

    canvas.save();
    canvas.translate(centroid.dx, centroid.dy);
    canvas.rotate(rotation);

    // Move points relative to centroid
    List<Offset> transformedPoints = points.map((p) => p - centroid).toList();

    // Draw the original shape
    for (int i = 0; i < transformedPoints.length - 1; i++) {
      canvas.drawLine(transformedPoints[i], transformedPoints[i + 1], linePaint);
    }

    // If the shape is closed, draw the outer version and connect the corners
    if (isClosed) {
      _drawOuterShape(canvas, linePaint, transformedPoints);
      _connectCorners(canvas, linePaint, transformedPoints);
    }

    canvas.restore();
  }

  // Method to draw the outer shape by scaling the points based on bounding box
  void _drawOuterShape(Canvas canvas, Paint paint, List<Offset> points) {
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
  void _connectCorners(Canvas canvas, Paint paint, List<Offset> points) {
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
    // Do nothing since LinearLinePainter doesn't use dragging to update
  }

  @override
  bool contains(Offset point) {
    // Transform point to shape's coordinate system
    Offset centroid = _calculateCentroid(points);
    Offset transformedPoint = _rotatePoint(point, centroid, -rotation);
    transformedPoint = (transformedPoint - centroid) / scaleFactor + centroid;

    // Inflate the area for easier selection
    for (int i = 0; i < points.length - 1; i++) {
      double distance = _distanceFromPointToLineSegment(
          points[i], points[i + 1], transformedPoint);
      if (distance <= 20.0) {
        return true;
      }
    }
    return false;
  }

  @override
  void translate(Offset offset) {
    for (int i = 0; i < points.length; i++) {
      points[i] += offset;
    }
    for (int i = 0; i < originalPoints.length; i++) {
      originalPoints[i] += offset;
    }
  }
}

class GridPainter extends CustomPainter {
  final List<Shape> shapes;
  final Shape? currentShape;
  final double gridSize;
  final Offset? lastTap; // Nullable Offset for the temporary dot
  final Shape? selectedShape;

  GridPainter(
      this.shapes,
      this.currentShape,
      this.gridSize,
      this.lastTap,
      this.selectedShape,
      );

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
      bool isSelected = shape == selectedShape;
      shape.draw(canvas, shapePaint, isSelected: isSelected);
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
      canvas.drawCircle(lastTap!, 5.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Utility function to calculate the distance from a point to a line segment
double _distanceFromPointToLineSegment(Offset a, Offset b, Offset p) {
  final double lengthSquared = (b - a).distanceSquared;
  if (lengthSquared == 0.0) return (p - a).distance;
  double t = ((p - a).dot(b - a)) / lengthSquared;
  t = t.clamp(0.0, 1.0);
  Offset projection = a + (b - a) * t;
  return (p - projection).distance;
}

// Extension on Offset for vector operations
extension OffsetExtensions on Offset {
  double dot(Offset other) => dx * other.dx + dy * other.dy;
  Offset operator *(double scalar) => Offset(dx * scalar, dy * scalar);
}

// Function to rotate a point around a center
Offset _rotatePoint(Offset point, Offset center, double angle) {
  double s = math.sin(angle);
  double c = math.cos(angle);

  // Translate point back to origin:
  point = point - center;

  // Rotate point
  double xnew = point.dx * c - point.dy * s;
  double ynew = point.dx * s + point.dy * c;

  // Translate point back:
  point = Offset(xnew, ynew) + center;
  return point;
}
