import 'dart:io';

void main() {
  for (var i = 1; i <= 4; i++) {
    final file = File('c:\\Users\\Stefanie\\Documents\\Mobile App Assignment\\Codu\\codu_app\\assets\\images\\Level Map $i.svg');
    if (!file.existsSync()) {
      print('Level Map $i.svg does not exist');
      continue;
    }
    final content = file.readAsStringSync();
    final regExp = RegExp(r'id="Path" d="([^"]+)"');
    final match = regExp.firstMatch(content);
    if (match != null) {
      final d = match.group(1);
      print('Level Map $i Path length: ${d?.length}');
    } else {
      // Try fallback regex
      final fallbackRegExp = RegExp(r'd="([^"]+)"');
      final matches = fallbackRegExp.allMatches(content);
      print('Level Map $i Fallback matches count: ${matches.length}');
      if (matches.isNotEmpty) {
        final last = matches.last.group(1);
        print('Level Map $i Last match length: ${last?.length}');
      }
    }
  }
}
