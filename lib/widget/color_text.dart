import 'package:flutter/material.dart';

class ColorText extends StatelessWidget {
  ColorText(
      {@required this.text,
      @required this.index,
      @required this.itemHeight,
      @required this.controller});
  final String text;
  final int index;
  final double itemHeight;
  final FixedExtentScrollController controller;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(100, itemHeight), //指定画布大小
      painter:
          ColorTextPainter(text: text, index: index, controller: controller),
    );
  }
}

class ColorTextPainter extends CustomPainter {
  ColorTextPainter(
      {@required this.text, @required this.index, @required this.controller});
  final String text;
  final int index;
  final FixedExtentScrollController controller;
  Offset position;
  @override
  void paint(Canvas canvas, Size size) {
    double offset = index * size.height - controller.offset;

    Paint painter = Paint();
    painter.color = Colors.white;
    painter.strokeWidth = 1;
    painter.style = PaintingStyle.fill;
    painter.isAntiAlias = true;

    if (offset.abs() >= size.height) {
      TextSpan span = new TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: "LED",
              fontSize: 32,
              color: Colors.white.withOpacity(0.3)));
      TextPainter tp = new TextPainter(
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          text: span);
      tp.layout(minWidth: size.width);

      tp.paint(canvas, Offset(0, (size.height - tp.height) / 2));
    } else {
      double cutPoint = offset >= 0 ? (size.height - offset) : offset.abs();

      TextSpan span = new TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: "LED",
              fontSize: 32,
              color: Colors.white.withOpacity(offset >= 0 ? 1 : 0.3)));
      TextPainter tp = new TextPainter(
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          text: span);
      tp.layout(minWidth: size.width);

      canvas.save();
      canvas.clipRect(Offset.zero & Size(size.width, cutPoint));
      tp.paint(canvas, Offset(0, (size.height - tp.height) / 2));
      canvas.restore();

      tp = TextPainter(
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          text: TextSpan(
              text: text,
              style: TextStyle(
                  fontFamily: "LED",
                  fontSize: 32,
                  color: Colors.white.withOpacity(offset >= 0 ? 0.3 : 1))))
        ..layout(minWidth: size.width);
      canvas.clipRect(Rect.fromPoints(
          Offset(0, cutPoint), Offset(size.width, size.height)));

      tp.paint(canvas, Offset(0, (size.height - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(ColorTextPainter oldDelegate) {
    return false;
  }
}
