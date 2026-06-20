import 'dart:io';

void main() {
  final file = File(r'c:\Users\Stefanie\Documents\Mobile App Assignment\Codu\codu_app\assets\images\Level Map 1.svg');
  final content = file.readAsStringSync();
  
  // Find all elements that look like tag openings
  final regExp = RegExp(r'<([a-zA-Z0-9:]+)([^>]*)>');
  final matches = regExp.allMatches(content);
  print('Found ${matches.length} elements:');
  for (final match in matches) {
    final tag = match.group(1);
    final attrs = match.group(2)!;
    if (tag == 'image') {
      print('<image ... (href omitted)>');
    } else if (tag == 'path') {
      final dMatch = RegExp(r'd="([^"]+)"').firstMatch(attrs);
      final idMatch = RegExp(r'id="([^"]+)"').firstMatch(attrs);
      print('<path id="${idMatch?.group(1)}" d_len="${dMatch?.group(1)?.length}">');
    } else if (attrs.length > 200) {
      print('<$tag ...>');
    } else {
      print('<$tag $attrs>');
    }
  }
}
