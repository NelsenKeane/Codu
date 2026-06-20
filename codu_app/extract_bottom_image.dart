import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/images/Level Map 1.svg');
  if (!file.existsSync()) {
    print("SVG file not found");
    return;
  }
  final content = file.readAsStringSync();
  final regex = RegExp(r'xlink:href="data:image/png;base64,([^"]+)"');
  final matches = regex.allMatches(content).toList();
  if (matches.length > 1) {
    final base64Data = matches[1].group(1)!;
    final bytes = base64.decode(base64Data);
    File('bottom_image.png').writeAsBytesSync(bytes);
    print("Success: Saved bottom_image.png");
  } else {
    print("Failure: Could not find second image base64, found ${matches.length} matches.");
  }
}
