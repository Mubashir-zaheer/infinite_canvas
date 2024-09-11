import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:random_color/random_color.dart';

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
