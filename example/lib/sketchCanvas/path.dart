import 'package:flutter/material.dart';

class DrawLineScreenState extends State<StatefulBuilder> {
  List<List<Offset>> shapes = [];
  List<Offset> currentShape = [];
  bool showGrid = false; // State to control the grid visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Draw Shapes')),
      body: GestureDetector(
        onTapUp: (details) {
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
        },
        child: CustomPaint(
          painter: LinePainter(shapes, currentShape, showGrid),
          child: Container(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'Grid'),
          BottomNavigationBarItem(icon: Icon(Icons.clear), label: 'Clear'),
        ],
        onTap: (index) {
          if (index == 0) {
            // Toggle grid visibility
            setState(() {
              showGrid = !showGrid;
            });
          } else if (index == 1) {
            // Clear all shapes
            setState(() {
              shapes.clear();
              currentShape.clear();
            });
          }
        },
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final List<List<Offset>> shapes;
  final List<Offset> currentShape;
  final bool showGrid;

  LinePainter(this.shapes, this.currentShape, this.showGrid);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    var pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Draw the grid if showGrid is true
    if (showGrid) {
      drawGrid(canvas, size);
    }

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

  void drawGrid(Canvas canvas, Size size) {
    var gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0;

    double step = 20.0; // Distance between grid lines

    // Draw vertical grid lines
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
