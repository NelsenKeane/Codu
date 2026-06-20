import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

void main() {
  final file = File(r'c:\Users\Stefanie\Documents\Mobile App Assignment\Codu\codu_app\assets\images\Level Map 1.svg');
  final content = file.readAsStringSync();
  final regExp = RegExp(r'd="([^"]+)"');
  final matches = regExp.allMatches(content);
  final d = matches.elementAt(4).group(1)!;
  
  final path = parseSvgPathData(d);
  final metrics = path.computeMetrics().toList();
  print('Number of metrics: ${metrics.length}');
  final metric = metrics.first;
  final totalLength = metric.length;
  print('Total path length: $totalLength');
  
  for (var i = 0; i < 10; i++) {
    final distance = (i / 9) * totalLength;
    final tangent = metric.getTangentForOffset(distance);
    print('Interval $i: distance=${distance.toStringAsFixed(1)}, position=${tangent?.position}');
  }
}
