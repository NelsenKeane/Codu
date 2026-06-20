import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

void main() {
  final file = File(r'c:\Users\Stefanie\Documents\Mobile App Assignment\Codu\codu_app\assets\images\Level Map 1.svg');
  final content = file.readAsStringSync();
  final regExp = RegExp(r'd="([^"]+)"');
  final matches = regExp.allMatches(content);
  final d = matches.elementAt(4).group(1)!;
  
  // Note: path_drawing doesn't need a running Flutter app to parse path data, 
  // but it returns a dart:ui Path.
  // Let's see if we can parse it. We need mock window or similar if we run outside Flutter,
  // but let's test if it compiles.
  print('Trying to parse path of length: ${d.length}');
  try {
    final path = parseSvgPathData(d);
    print('Successfully parsed! Path bounds: ${path.getBounds()}');
  } catch (e) {
    print('Failed to parse: $e');
  }
}
