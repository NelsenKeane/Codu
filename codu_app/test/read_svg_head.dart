import 'dart:io';

void main() {
  final file = File(r'c:\Users\Stefanie\Documents\Mobile App Assignment\Codu\codu_app\assets\images\Level Map 1.svg');
  final content = file.readAsStringSync();
  print(content.substring(0, 1000));
}
