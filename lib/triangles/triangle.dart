import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';


class Vertex {
  Offset point;

  Vertex({required this.point});
}


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<Vertex> vertices = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: _onTapDown,


        child: CustomPaint(
          foregroundPainter: PointPainter(
            vertices: vertices,
          ),
          painter: LinesPainter(
            vertices: vertices,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      if(vertices.length >= 3) vertices.clear();
      else vertices.add(Vertex(point: details.globalPosition));
    });
    print(vertices);
  }
}

class PointPainter extends CustomPainter {
  List<Vertex> vertices;
  PointPainter({required this.vertices});


  @override
  void paint(Canvas canvas, Size size) {

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 30.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPoints(PointMode.points, vertices.map((e) => e.point).toList(), paint);


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

}



class LinesPainter extends CustomPainter {

  List<Vertex> vertices;
  LinesPainter({required this.vertices});


  @override
  void paint(Canvas canvas, Size size) {

    

    Paint linefill = Paint()
      ..color = Colors.blue
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;
    
   
    

    if (vertices.length >= 3) {

      Path path = Path()..moveTo(vertices[0].point.dx, vertices[0].point.dy);
    
      for (int i = 0; i < vertices.length; i++) {
        Offset next = vertices[(i+1) % vertices.length].point;
        path..lineTo(next.dx, next.dy);    
      }
      canvas.drawPath(path, linefill);
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
