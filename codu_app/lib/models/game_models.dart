import 'dart:math';

class CodeSegment {
  final String text; // If slot, it is the slot ID (e.g. "slot_0")
  final bool isSlot;
  final String? placeholder; // e.g. "..."

  CodeSegment.text(this.text)
      : isSlot = false,
        placeholder = null;

  CodeSegment.slot(this.text, {this.placeholder}) : isSlot = true;
}

class CodingQuestion {
  final String instruction;
  final List<List<CodeSegment>> codeLines;
  final List<String> choices;
  final Map<String, String> correctAnswers; // slotId -> correctValue

  CodingQuestion({
    required this.instruction,
    required this.codeLines,
    required this.choices,
    required this.correctAnswers,
  });
}

class QuestionBank {
  static List<CodingQuestion> getQuestionsForLevel(int levelNumber, String subject) {
    final String cleanSubject = subject;
    
    // Seed random generator per level to ensure consistent questions for the same level
    final Random rand = Random(levelNumber * 13 + cleanSubject.hashCode);
    
    // Map levels to topics (0 to 9)
    // 0: Console Output / Basics
    // 1: Variables & Data Types
    // 2: Math Operations
    // 3: String Manipulation
    // 4: Simple Conditions (If)
    // 5: Complex Conditions (If-Else)
    // 6: Logical Operators
    // 7: While Loops
    // 8: For Loops
    // 9: Arrays / Lists / Collections
    final int topicIndex = (levelNumber - 1) % 10;
    
    List<CodingQuestion> list = [];
    for (int q = 0; q < 10; q++) {
      list.add(_generateQuestion(cleanSubject, topicIndex, levelNumber, q, rand));
    }
    return list;
  }

  static String getTopicTitle(int levelNumber, String subject) {
    final String cleanSubject = subject;
    final int topicIndex = (levelNumber - 1) % 10;
    
    switch (topicIndex) {
      case 0:
        return "$cleanSubject Output Basics";
      case 1:
        return "$cleanSubject Variables";
      case 2:
        return "$cleanSubject Math Operations";
      case 3:
        return "$cleanSubject String Handling";
      case 4:
        return "$cleanSubject If Statements";
      case 5:
        return "$cleanSubject Conditionals (If-Else)";
      case 6:
        return "$cleanSubject Logical Operators";
      case 7:
        return "$cleanSubject While Loops";
      case 8:
        return "$cleanSubject For Loops";
      case 9:
        return "$cleanSubject Collections & Arrays";
      default:
        return "$cleanSubject Logic";
    }
  }

  static CodingQuestion _generateQuestion(String lang, int topic, int level, int questionIndex, Random rand) {
    if (lang == 'Python') {
      return _generatePythonQuestion(topic, level, questionIndex, rand);
    } else if (lang == 'Javascript') {
      return _generateJSQuestion(topic, level, questionIndex, rand);
    } else if (lang == 'C++') {
      return _generateCppQuestion(topic, level, questionIndex, rand);
    } else {
      // Default to Java
      return _generateJavaQuestion(topic, level, questionIndex, rand);
    }
  }

  // --- PYTHON QUESTION GENERATION ---
  static CodingQuestion _generatePythonQuestion(int topic, int level, int qIndex, Random rand) {
    switch (topic) {
      case 0: // Output Basics
        if (qIndex % 2 == 0) {
          final messages = ["Hello, World!", "Welcome to Codu!", "Python is fun!", "Learn to Code!", "Level Complete!"];
          final msg = messages[qIndex % messages.length];
          return CodingQuestion(
            instruction: "Complete the Python code to print \"$msg\" to the console.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.slot("s1"),
                CodeSegment.slot("s2"),
              ]
            ],
            choices: _shuffle(["print (", "\"$msg\"", ")", "printf(", "show(", "display("], rand),
            correctAnswers: {"s0": "print (", "s1": "\"$msg\"", "s2": ")"},
          );
        } else {
          final wordPairs = [
            ["Hello", "World"],
            ["Codu", "Rules"],
            ["Learn", "Code"],
            ["Keep", "Coding"],
            ["Python", "Rocks"],
          ];
          final pair = wordPairs[(qIndex ~/ 2) % wordPairs.length];
          final w1 = pair[0];
          final w2 = pair[1];
          return CodingQuestion(
            instruction: "Complete the code to print both \"$w1\" and \"$w2\" on separate lines.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text("(\"$w1\")")],
              [CodeSegment.text("print"), CodeSegment.slot("s1")]
            ],
            choices: _shuffle(["print", "(\"$w2\")", "show", "printf", "log", "display"], rand),
            correctAnswers: {"s0": "print", "s1": "(\"$w2\")"},
          );
        }
      
      case 1: // Variables & Data Types
        final varNames = ["x", "score", "age", "count", "points"];
        final name = varNames[qIndex % varNames.length];
        if (qIndex % 2 == 0) {
          final val = (qIndex + 1) * 5;
          return CodingQuestion(
            instruction: "Set the variable '$name' to the value $val and print it.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" = "),
                CodeSegment.slot("s1"),
              ],
              [
                CodeSegment.text("print("),
                CodeSegment.slot("s2"),
                CodeSegment.text(")"),
              ]
            ],
            choices: _shuffle([name, "$val", name, "var", "let", "val"], rand),
            correctAnswers: {"s0": name, "s1": "$val", "s2": name},
          );
        } else {
          final varPairs = [
            ["name", "\"Codu\"", "age", "5"],
            ["title", "\"Master\"", "level", "10"],
            ["hero", "\"Nelsen\"", "health", "4"],
            ["item", "\"Sword\"", "qty", "1"],
            ["pet", "\"Dog\"", "weight", "12"],
          ];
          final vp = varPairs[(qIndex ~/ 2) % varPairs.length];
          final strVar = vp[0];
          final strVal = vp[1];
          final numVar = vp[2];
          final numVal = vp[3];
          return CodingQuestion(
            instruction: "Define a string variable '$strVar' with $strVal and a number '$numVar' with $numVal.",
            codeLines: [
              [CodeSegment.text("$strVar = "), CodeSegment.slot("s0")],
              [CodeSegment.slot("s1"), CodeSegment.text(" = "), CodeSegment.slot("s2")]
            ],
            choices: _shuffle([strVal, numVar, numVal, "let", "var", "int"], rand),
            correctAnswers: {"s0": strVal, "s1": numVar, "s2": numVal},
          );
        }

      case 2: // Math Operations
        final a = (qIndex + 2) * 3;
        final b = (qIndex + 1) * 2;
        if (qIndex % 2 == 0) {
          final sum = a + b;
          return CodingQuestion(
            instruction: "Calculate the sum of $a and $b using addition.",
            codeLines: [
              [
                CodeSegment.text("x = "),
                CodeSegment.slot("s0"),
              ],
              [
                CodeSegment.text("y = "),
                CodeSegment.slot("s1"),
              ],
              [
                CodeSegment.text("result = x "),
                CodeSegment.slot("s2"),
                CodeSegment.text(" y"),
              ],
              [
                CodeSegment.text("print(result) # Should print $sum"),
              ]
            ],
            choices: _shuffle(["$a", "$b", "+", "-", "*", "/", "%"], rand),
            correctAnswers: {"s0": "$a", "s1": "$b", "s2": "+"},
          );
        } else {
          final mathTriples = [
            ["price", "2", "total", "10", "*"],
            ["height", "3", "scaled", "5", "*"],
            ["width", "4", "area", "2", "*"],
            ["base", "5", "result", "3", "*"],
            ["speed", "2", "distance", "15", "*"],
          ];
          final mt = mathTriples[(qIndex ~/ 2) % mathTriples.length];
          final vName = mt[0];
          final factor = mt[1];
          final target = mt[2];
          final initVal = mt[3];
          final op = mt[4];
          return CodingQuestion(
            instruction: "Multiply the variable '$vName' by $factor and store it in '$target'.",
            codeLines: [
              [CodeSegment.text("$vName = $initVal")],
              [CodeSegment.slot("s0"), CodeSegment.text(" = $vName "), CodeSegment.slot("s1"), CodeSegment.slot("s2")]
            ],
            choices: _shuffle([target, op, factor, "+", "x", "double", "="], rand),
            correctAnswers: {"s0": target, "s1": op, "s2": factor},
          );
        }

      case 3: // String Handling
        final word = ["Python", "Codu", "Hello", "Code", "Robot"][qIndex % 5];
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Find the length of the string \"$word\" and print it.",
            codeLines: [
              [
                CodeSegment.text("text = "),
                CodeSegment.slot("s0"),
              ],
              [
                CodeSegment.text("length = "),
                CodeSegment.slot("s1"),
                CodeSegment.text("("),
                CodeSegment.slot("s2"),
                CodeSegment.text(")"),
              ],
              [
                CodeSegment.text("print(length)"),
              ]
            ],
            choices: _shuffle(["\"$word\"", "len", "text", "length", "size", "count"], rand),
            correctAnswers: {"s0": "\"$word\"", "s1": "len", "s2": "text"},
          );
        } else {
          final wordPairs = [
            ["a", "\"Hello \"", "b", "\"World\"", "combined"],
            ["first", "\"John \"", "last", "\"Doe\"", "fullName"],
            ["part1", "\"Codu \"", "part2", "\"App\"", "fullTitle"],
            ["str1", "\"Go \"", "str2", "\"Deep\"", "res"],
            ["w1", "\"Super \"", "w2", "\"Star\"", "superstar"],
          ];
          final wp = wordPairs[(qIndex ~/ 2) % wordPairs.length];
          final v1 = wp[0];
          final val1 = wp[1];
          final v2 = wp[2];
          final val2 = wp[3];
          final target = wp[4];
          return CodingQuestion(
            instruction: "Concatenate string '$v1' and '$v2' and print the combined result.",
            codeLines: [
              [CodeSegment.text("$v1 = $val1")],
              [CodeSegment.text("$v2 = $val2")],
              [CodeSegment.text("$target = $v1 "), CodeSegment.slot("s0"), CodeSegment.slot("s1")],
              [CodeSegment.slot("s2"), CodeSegment.text("($target)")]
            ],
            choices: _shuffle(["+", v2, "print", "concat", "join", "show"], rand),
            correctAnswers: {"s0": "+", "s1": v2, "s2": "print"},
          );
        }

      case 4: // Simple Conditions (If)
        final val = (qIndex + 1) * 10;
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Complete the condition so the message prints when 'score' is greater than $val.",
            codeLines: [
              [
                CodeSegment.text("score = "),
                CodeSegment.slot("s0"),
              ],
              [
                CodeSegment.slot("s1"),
                CodeSegment.text(" score "),
                CodeSegment.slot("s2"),
                CodeSegment.text(" $val:"),
              ],
              [
                CodeSegment.text("    print(\"You Win!\")"),
              ]
            ],
            choices: _shuffle(["${val + 5}", "if", ">", "<", "==", "else", "then"], rand),
            correctAnswers: {"s0": "${val + 5}", "s1": "if", "s2": ">"},
          );
        } else {
          final condPairs = [
            ["is_logged_in", "True"],
            ["has_access", "True"],
            ["is_active", "True"],
            ["is_valid", "True"],
            ["can_play", "True"],
          ];
          final cp = condPairs[(qIndex ~/ 2) % condPairs.length];
          final varName = cp[0];
          final boolVal = cp[1];
          return CodingQuestion(
            instruction: "Complete the condition so the message prints when '$varName' is $boolVal.",
            codeLines: [
              [CodeSegment.text("$varName = $boolVal")],
              [CodeSegment.slot("s0"), CodeSegment.text(" $varName "), CodeSegment.slot("s1"), CodeSegment.slot("s2")]
            ],
            choices: _shuffle(["if", "==", "$boolVal:", "False:", "while", "else", "then"], rand),
            correctAnswers: {"s0": "if", "s1": "==", "s2": "$boolVal:"},
          );
        }

      case 5: // Complex Conditions (If-Else)
        final age = (qIndex + 1) * 4 + 10;
        final passAge = 18;
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Fill in the if-else block. If age is >= $passAge, print \"Yes\", else print \"No\".",
            codeLines: [
              [
                CodeSegment.text("age = $age"),
              ],
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" age >= $passAge:"),
              ],
              [
                CodeSegment.text("    print(\"Yes\")"),
              ],
              [
                CodeSegment.slot("s1"),
              ],
              [
                CodeSegment.text("    print(\"No\")"),
              ]
            ],
            choices: _shuffle(["if", "else:", "elif", "then", "otherwise"], rand),
            correctAnswers: {"s0": "if", "s1": "else:"},
          );
        } else {
          final tempTriples = [
            ["temp", "32", "30", "\"Hot\"", "\"Cold\""],
            ["score", "85", "80", "\"Pass\"", "\"Fail\""],
            ["speed", "75", "70", "\"Fast\"", "\"Slow\""],
            ["level", "12", "10", "\"Pro\"", "\"Noob\""],
            ["health", "45", "50", "\"Weak\"", "\"Strong\""],
          ];
          final tt = tempTriples[(qIndex ~/ 2) % tempTriples.length];
          final varName = tt[0];
          final initVal = tt[1];
          final threshold = tt[2];
          final msg1 = tt[3];
          final msg2 = tt[4];
          return CodingQuestion(
            instruction: "Write a condition checking if $varName is greater than $threshold. If yes, print $msg1, otherwise print $msg2.",
            codeLines: [
              [CodeSegment.text("$varName = $initVal")],
              [CodeSegment.slot("s0"), CodeSegment.text(" $varName > $threshold:")],
              [CodeSegment.text("    print($msg1)")],
              [CodeSegment.slot("s1")],
              [CodeSegment.text("    print($msg2)")]
            ],
            choices: _shuffle(["if", "else:", "elif", "then", "otherwise"], rand),
            correctAnswers: {"s0": "if", "s1": "else:"},
          );
        }

      case 6: // Logical Operators
        final hour = 14;
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Complete the condition to print \"Open\" if hour is between 9 and 17 (inclusive).",
            codeLines: [
              [
                CodeSegment.text("hour = $hour"),
              ],
              [
                CodeSegment.text("if hour >= 9 "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" hour "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" 17:"),
              ],
              [
                CodeSegment.text("    print(\"Open\")"),
              ]
            ],
            choices: _shuffle(["and", "<=", "or", "not", ">", "=="], rand),
            correctAnswers: {"s0": "and", "s1": "<="},
          );
        } else {
          final logicTriples = [
            ["has_permission", "is_admin", "\"Access Granted\"", "or"],
            ["has_key", "knows_code", "\"Door Opens\"", "or"],
            ["is_weekend", "on_holiday", "\"Sleep In\"", "or"],
            ["has_coupon", "is_member", "\"Discount\"", "or"],
            ["can_swim", "has_lifesaver", "\"Enter Pool\"", "or"],
          ];
          final lt = logicTriples[(qIndex ~/ 2) % logicTriples.length];
          final v1 = lt[0];
          final v2 = lt[1];
          final msg = lt[2];
          final op = lt[3];
          return CodingQuestion(
            instruction: "Print $msg if $v1 is True OR $v2 is True.",
            codeLines: [
              [CodeSegment.text("$v1 = False")],
              [CodeSegment.text("$v2 = True")],
              [CodeSegment.text("if $v1 "), CodeSegment.slot("s0"), CodeSegment.slot("s1"), CodeSegment.text(":")],
              [CodeSegment.text("    print("), CodeSegment.slot("s2"), CodeSegment.text(")")]
            ],
            choices: _shuffle([op, v2, msg, "and", "not", "print"], rand),
            correctAnswers: {"s0": op, "s1": v2, "s2": msg},
          );
        }

      case 7: // While Loops
        final limit = qIndex + 2;
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Complete the loop to run while 'i' is less than $limit.",
            codeLines: [
              [
                CodeSegment.text("i = 0"),
              ],
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" i "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" $limit:"),
              ],
              [
                CodeSegment.text("    print(i)"),
              ],
              [
                CodeSegment.text("    i "),
                CodeSegment.slot("s2"),
                CodeSegment.text(" 1"),
              ]
            ],
            choices: _shuffle(["while", "<", "+=", "if", ">", "="], rand),
            correctAnswers: {"s0": "while", "s1": "<", "s2": "+="},
          );
        } else {
          final whilePairs = [
            ["count", "3", ">", "-="],
            ["timer", "5", ">", "-="],
            ["lives", "4", ">", "-="],
            ["steps", "6", ">", "-="],
            ["items", "10", ">", "-="],
          ];
          final wp = whilePairs[(qIndex ~/ 2) % whilePairs.length];
          final vName = wp[0];
          final startVal = wp[1];
          final comp = wp[2];
          final op = wp[3];
          return CodingQuestion(
            instruction: "Complete the while loop to print $vName down from $startVal to 1.",
            codeLines: [
              [CodeSegment.text("$vName = $startVal")],
              [CodeSegment.slot("s0"), CodeSegment.text(" $vName "), CodeSegment.slot("s1"), CodeSegment.text(" 0:")],
              [CodeSegment.text("    print($vName)")],
              [CodeSegment.text("    $vName "), CodeSegment.slot("s2"), CodeSegment.text(" 1")]
            ],
            choices: _shuffle(["while", comp, op, "if", "<", "="], rand),
            correctAnswers: {"s0": "while", "s1": comp, "s2": op},
          );
        }

      case 8: // For Loops
        final limit = qIndex + 3;
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Write a for loop to print numbers from 0 to ${limit - 1}.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" i "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" range("),
                CodeSegment.slot("s2"),
                CodeSegment.text("):"),
              ],
              [
                CodeSegment.text("    print(i)"),
              ]
            ],
            choices: _shuffle(["for", "in", "$limit", "while", "range", "list"], rand),
            correctAnswers: {"s0": "for", "s1": "in", "s2": "$limit"},
          );
        } else {
          final loopPairs = [
            ["names", "[\"Codu\", \"Bot\"]", "n"],
            ["colors", "[\"Red\", \"Blue\"]", "c"],
            ["digits", "[1, 2, 3]", "d"],
            ["fruits", "[\"Apple\", \"Plum\"]", "f"],
            ["words", "[\"hi\", \"bye\"]", "w"],
          ];
          final lp = loopPairs[(qIndex ~/ 2) % loopPairs.length];
          final listName = lp[0];
          final listExpr = lp[1];
          final varName = lp[2];
          return CodingQuestion(
            instruction: "Loop through a list of $listName and print each one.",
            codeLines: [
              [CodeSegment.text("$listName = $listExpr")],
              [CodeSegment.slot("s0"), CodeSegment.text(" $varName "), CodeSegment.slot("s1"), CodeSegment.slot("s2"), CodeSegment.text(":")],
              [CodeSegment.text("    print($varName)")]
            ],
            choices: _shuffle(["for", "in", listName, "while", "each", "loop"], rand),
            correctAnswers: {"s0": "for", "s1": "in", "s2": listName},
          );
        }

      case 9: // Collections / Lists
        final item = ["apple", "banana", "cherry", "grape", "orange"][qIndex % 5];
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Create a list of fruits and add '$item' to the list.",
            codeLines: [
              [
                CodeSegment.text("fruits = "),
                CodeSegment.slot("s0"),
              ],
              [
                CodeSegment.text("fruits."),
                CodeSegment.slot("s1"),
                CodeSegment.text("("),
                CodeSegment.slot("s2"),
                CodeSegment.text(")"),
              ]
            ],
            choices: _shuffle(["[]", "append", "\"$item\"", "add", "insert", "fruits"], rand),
            correctAnswers: {"s0": "[]", "s1": "append", "s2": "\"$item\""},
          );
        } else {
          final colorsPairs = [
            ["colors", "[\"Red\", \"Green\"]", "first", "0"],
            ["numbers", "[10, 20, 30]", "item", "0"],
            ["cities", "[\"Paris\", \"Tokyo\"]", "first_city", "0"],
            ["prices", "[5, 9, 15]", "val", "0"],
            ["letters", "[\"a\", \"b\"]", "let", "0"],
          ];
          final cp = colorsPairs[(qIndex ~/ 2) % colorsPairs.length];
          final listName = cp[0];
          final listExpr = cp[1];
          final target = cp[2];
          final idx = cp[3];
          return CodingQuestion(
            instruction: "Print the first element of the '$listName' list.",
            codeLines: [
              [CodeSegment.text("$listName = $listExpr")],
              [CodeSegment.text("$target = $listName["), CodeSegment.slot("s0"), CodeSegment.text("]")],
              [CodeSegment.slot("s1"), CodeSegment.text("("), CodeSegment.slot("s2"), CodeSegment.text(")")]
            ],
            choices: _shuffle([idx, "print", target, "1", "show", listName], rand),
            correctAnswers: {"s0": idx, "s1": "print", "s2": target},
          );
        }
      
      
      default:
        return _defaultFallbackQuestion("Python", rand);
    }
  }

  // --- JAVASCRIPT QUESTION GENERATION ---
  static CodingQuestion _generateJSQuestion(int topic, int level, int qIndex, Random rand) {
    switch (topic) {
      case 0: // Output Basics
        if (qIndex % 2 == 0) {
          final messages = ["Hello!", "JS is Alive", "Welcome", "Codu Player", "Success"];
          final msg = messages[qIndex % messages.length];
          return CodingQuestion(
            instruction: "Complete the JavaScript code to log \"$msg\" to the console.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text("."),
                CodeSegment.slot("s1"),
                CodeSegment.text("("),
                CodeSegment.slot("s2"),
                CodeSegment.text(");"),
              ]
            ],
            choices: _shuffle(["console", "log", "\"$msg\"", "print", "write", "warn"], rand),
            correctAnswers: {"s0": "console", "s1": "log", "s2": "\"$msg\""},
          );
        } else {
          final alertMsgs = ["\"Hello\"", "\"Codu\"", "\"Ready?\"", "\"Start\"", "\"Winner\""];
          final alertMsg = alertMsgs[(qIndex ~/ 2) % alertMsgs.length];
          return CodingQuestion(
            instruction: "Complete the JavaScript code to trigger an alert dialog with $alertMsg.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text("("),
                CodeSegment.slot("s1"),
                CodeSegment.text(");"),
              ]
            ],
            choices: _shuffle(["alert", alertMsg, "popup", "message", "dialog", "prompt"], rand),
            correctAnswers: {"s0": "alert", "s1": alertMsg},
          );
        }

      case 1: // Variables & Data Types
        final name = ["user", "counter", "status", "points", "total"][qIndex % 5];
        if (qIndex % 2 == 0) {
          final val = (qIndex + 1) * 10;
          return CodingQuestion(
            instruction: "Declare a constant variable '$name' and initialize it with value $val.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.slot("s1"),
                CodeSegment.text(" = "),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["const", name, "$val", "var", "let", "new"], rand),
            correctAnswers: {"s0": "const", "s1": name, "s2": "$val"},
          );
        } else {
          final varTriples = [
            ["score", "100"],
            ["level", "5"],
            ["lives", "4"],
            ["speed", "50"],
            ["count", "0"],
          ];
          final vt = varTriples[(qIndex ~/ 2) % varTriples.length];
          final vName = vt[0];
          final vVal = vt[1];
          return CodingQuestion(
            instruction: "Declare a reassignable variable '$vName' using modern ES6 syntax and set it to $vVal.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.slot("s1"),
                CodeSegment.text(" = "),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["let", vName, vVal, "const", "var", "new"], rand),
            correctAnswers: {"s0": "let", "s1": vName, "s2": vVal},
          );
        }

      case 2: // Math Operations
        final a = (qIndex + 2) * 5;
        final b = (qIndex + 1) * 3;
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Define standard JS arithmetic. Calculate the remainder of $a divided by $b.",
            codeLines: [
              [
                CodeSegment.text("let remainder = "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" "),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["$a", "%", "$b", "/", "*", "+", "let"], rand),
            correctAnswers: {"s0": "$a", "s1": "%", "s2": "$b"},
          );
        } else {
          final incVars = ["count", "index", "score", "clicks", "total"];
          final iName = incVars[(qIndex ~/ 2) % incVars.length];
          return CodingQuestion(
            instruction: "Increment variable '$iName' by 1 in Javascript.",
            codeLines: [
              [CodeSegment.text("let $iName = 5;")],
              [CodeSegment.text(iName), CodeSegment.slot("s0"), CodeSegment.slot("s1")]
            ],
            choices: _shuffle(["+", "+", "=", "++", "1", ";"], rand),
            correctAnswers: {"s0": "+", "s1": "+"},
          );
        }

      case 3: // String Handling
        final str = ["js", "codu", "code", "dev", "app"][qIndex % 5];
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Get the length of the string \"$str\".",
            codeLines: [
              [
                CodeSegment.text("let s = \"$str\";"),
              ],
              [
                CodeSegment.text("let len = s."),
                CodeSegment.slot("s0"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["length", "size", "count", "len()", "length()"], rand),
            correctAnswers: {"s0": "length"},
          );
        } else {
          final useUpper = (qIndex ~/ 2) % 2 == 0;
          final method = useUpper ? "toUpperCase" : "toLowerCase";
          final desc = useUpper ? "uppercase" : "lowercase";
          return CodingQuestion(
            instruction: "Convert string 's' to $desc.",
            codeLines: [
              [CodeSegment.text("let s = \"$str\";")],
              [CodeSegment.text("let result = s."), CodeSegment.slot("s0"), CodeSegment.slot("s1"), CodeSegment.slot("s2")]
            ],
            choices: _shuffle([method, "(", ")", "upper", "toUpper", "caps"], rand),
            correctAnswers: {"s0": method, "s1": "(", "s2": ")"},
          );
        }

      case 4: // Simple Conditions (If)
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Write a condition checking if value 'x' is strictly equal to 10.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" (x "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" 10) {"),
              ],
              [
                CodeSegment.text("    console.log(\"Ten\");"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["if", "===", "==", "=", "when", "elif"], rand),
            correctAnswers: {"s0": "if", "s1": "==="},
          );
        } else {
          final agePairs = [
            ["age", "18", "showForm"],
            ["score", "50", "showPass"],
            ["speed", "60", "showWarning"],
            ["lives", "1", "showGameOver"],
            ["temp", "30", "showAC"],
          ];
          final ap = agePairs[(qIndex ~/ 2) % agePairs.length];
          final varName = ap[0];
          final threshold = ap[1];
          final fnName = ap[2];
          return CodingQuestion(
            instruction: "Check if variable '$varName' is less than $threshold.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ($varName "), CodeSegment.slot("s1"), CodeSegment.text(" $threshold) {")].toList(),
              [CodeSegment.text("    $fnName();")].toList(),
              [CodeSegment.text("}")].toList()
            ],
            choices: _shuffle(["if", "<", ">", "==", "else", "then"], rand),
            correctAnswers: {"s0": "if", "s1": "<"},
          );
        }

      case 5: // Complex Conditions (If-Else)
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Fill in the JavaScript else clause syntax.",
            codeLines: [
              [
                CodeSegment.text("if (isOk) {"),
              ],
              [
                CodeSegment.text("    run();"),
              ],
              [
                CodeSegment.text("} "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" {"),
              ],
              [
                CodeSegment.slot("s1"),
                CodeSegment.text("();"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["else", "stop", "otherwise", "then", "catch"], rand),
            correctAnswers: {"s0": "else", "s1": "stop"},
          );
        } else {
          final stateTriples = [
            ["status", "\"active\"", "init", "close"],
            ["mode", "\"dark\"", "setDark", "setLight"],
            ["role", "\"admin\"", "grantAccess", "denyAccess"],
            ["state", "\"loading\"", "showSpinner", "hideSpinner"],
            ["user", "\"guest\"", "showLogin", "showProfile"],
          ];
          final st = stateTriples[(qIndex ~/ 2) % stateTriples.length];
          final varName = st[0];
          final valExpr = st[1];
          final fn1 = st[2];
          final fn2 = st[3];
          return CodingQuestion(
            instruction: "Fill in if-else syntax. If $varName is $valExpr, call $fn1(), else call $fn2().",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ($varName === $valExpr) {")],
              [CodeSegment.text("    $fn1();")],
              [CodeSegment.text("} "), CodeSegment.slot("s1"), CodeSegment.text(" {")],
              [CodeSegment.text("    $fn2();")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["if", "else", "then", "otherwise", "elif"], rand),
            correctAnswers: {"s0": "if", "s1": "else"},
          );
        }

      case 6: // Logical Operators
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Check if either 'isAdmin' OR 'isOwner' is true in JavaScript.",
            codeLines: [
              [
                CodeSegment.text("if (isAdmin "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" isOwner) {"),
              ],
              [
                CodeSegment.text("    "),
                CodeSegment.slot("s1"),
                CodeSegment.text(".log(\"Access granted\");"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["||", "console", "&&", "or", "window", "system"], rand),
            correctAnswers: {"s0": "||", "s1": "console"},
          );
        } else {
          final hasAccountPairs = [
            ["hasAccount", "isLoggedIn", "Dashboard"],
            ["isValid", "hasToken", "Home"],
            ["isMember", "hasBalance", "Shop"],
            ["hasAccess", "isVerified", "Settings"],
            ["canEnter", "hasTicket", "Event"],
          ];
          final hap = hasAccountPairs[(qIndex ~/ 2) % hasAccountPairs.length];
          final v1 = hap[0];
          final v2 = hap[1];
          final pageName = hap[2];
          return CodingQuestion(
            instruction: "Check if both '$v1' AND '$v2' are true.",
            codeLines: [
              [CodeSegment.text("if ($v1 "), CodeSegment.slot("s0"), CodeSegment.text(" $v2) {")],
              [CodeSegment.slot("s1"), CodeSegment.text(".log(\"$pageName\");")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["&&", "console", "||", "and", "alert", "window"], rand),
            correctAnswers: {"s0": "&&", "s1": "console"},
          );
        }

      case 7: // While Loops
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Complete the while loop to increment count up to 5.",
            codeLines: [
              [
                CodeSegment.text("let count = 0;"),
              ],
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" (count < 5) {"),
              ],
              [
                CodeSegment.text("    count"),
                CodeSegment.slot("s1"),
                CodeSegment.text(";"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["while", "++", "+=", "loop", "for", "--"], rand),
            correctAnswers: {"s0": "while", "s1": "++"},
          );
        } else {
          final flagPairs = [
            ["flag", "processTask"],
            ["isRunning", "updatePhysics"],
            ["isActive", "checkMessages"],
            ["loading", "fetchData"],
            ["playing", "renderFrame"],
          ];
          final fp = flagPairs[(qIndex ~/ 2) % flagPairs.length];
          final vName = fp[0];
          final fnName = fp[1];
          return CodingQuestion(
            instruction: "Complete loop checking if $vName is active.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ($vName) {")],
              [CodeSegment.text("    $fnName();")],
              [CodeSegment.text("    $vName = "), CodeSegment.slot("s1"), CodeSegment.text(";")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["while", "false", "true", "for", "if", "null"], rand),
            correctAnswers: {"s0": "while", "s1": "false"},
          );
        }

      case 8: // For Loops
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Write a standard JavaScript for loop counting from 0 to 4.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" (let i = 0; i "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" 5; i++) {"),
              ],
              [
                CodeSegment.text("    console.log(i);"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["for", "<", ">", "while", "++", "in"], rand),
            correctAnswers: {"s0": "for", "s1": "<"},
          );
        } else {
          final ofPairs = [
            ["items", "[1, 2]", "item"],
            ["users", "[\"A\", \"B\"]", "u"],
            ["colors", "[\"red\", \"blue\"]", "c"],
            ["prices", "[10, 20]", "p"],
            ["scores", "[80, 90]", "s"],
          ];
          final opPairs = ofPairs[(qIndex ~/ 2) % ofPairs.length];
          final arrName = opPairs[0];
          final arrVal = opPairs[1];
          final elName = opPairs[2];
          return CodingQuestion(
            instruction: "Loop through array elements in JS using for...of loop.",
            codeLines: [
              [CodeSegment.text("let $arrName = $arrVal;")],
              [CodeSegment.slot("s0"), CodeSegment.text(" (let $elName "), CodeSegment.slot("s1"), CodeSegment.slot("s2"), CodeSegment.text(") {")],
              [CodeSegment.text("    console.log($elName);")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["for", "of", arrName, "in", "each", "let"], rand),
            correctAnswers: {"s0": "for", "s1": "of", "s2": arrName},
          );
        }

      case 9: // Collections / Arrays
        final item = ["apple", "grape", "orange"][qIndex % 3];
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Push the fruit \"$item\" onto the end of the array.",
            codeLines: [
              [
                CodeSegment.text("let arr = [];"),
              ],
              [
                CodeSegment.text("arr."),
                CodeSegment.slot("s0"),
                CodeSegment.text("("),
                CodeSegment.slot("s1"),
                CodeSegment.text(");"),
              ]
            ],
            choices: _shuffle(["push", "\"$item\"", "add", "append", "pop", "insert"], rand),
            correctAnswers: {"s0": "push", "s1": "\"$item\""},
          );
        } else {
          final listPairs = [
            ["list", "[\"A\", \"B\"]", "first", "0"],
            ["colors", "[\"red\", \"green\"]", "myColor", "0"],
            ["speeds", "[50, 100]", "initialSpeed", "0"],
            ["cards", "[10, 11]", "firstCard", "0"],
            ["names", "[\"Bob\", \"Tim\"]", "mainName", "0"],
          ];
          final lp = listPairs[(qIndex ~/ 2) % listPairs.length];
          final lName = lp[0];
          final lVal = lp[1];
          final target = lp[2];
          final idx = lp[3];
          return CodingQuestion(
            instruction: "Get the first item of array '$lName' in JS.",
            codeLines: [
              [CodeSegment.text("let $lName = $lVal;")],
              [CodeSegment.text("let $target = $lName["), CodeSegment.slot("s0"), CodeSegment.text("];")],
              [CodeSegment.slot("s1"), CodeSegment.text(".log($target);")]
            ],
            choices: _shuffle([idx, "console", "1", "print", "window", "document"], rand),
            correctAnswers: {"s0": idx, "s1": "console"},
          );
        }

      default:
        return _defaultFallbackQuestion("Javascript", rand);
    }
  }

  // --- C++ QUESTION GENERATION ---
  static CodingQuestion _generateCppQuestion(int topic, int level, int qIndex, Random rand) {
    switch (topic) {
      case 0: // Output Basics
        if (qIndex % 2 == 0) {
          final messages = ["Hello C++", "Codu C++", "Fast Code"];
          final msg = messages[qIndex % messages.length];
          return CodingQuestion(
            instruction: "Print \"$msg\" to the console using C++ std::cout.",
            codeLines: [
              [
                CodeSegment.text("std::"),
                CodeSegment.slot("s0"),
                CodeSegment.text(" << "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" << std::"),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["cout", "\"$msg\"", "endl", "cin", "print", "newline"], rand),
            correctAnswers: {"s0": "cout", "s1": "\"$msg\"", "s2": "endl"},
          );
        } else {
          final inputPairs = [
            ["age", "int"],
            ["score", "int"],
            ["height", "double"],
            ["width", "float"],
            ["count", "int"],
          ];
          final ip = inputPairs[(qIndex ~/ 2) % inputPairs.length];
          final varName = ip[0];
          final type = ip[1];
          return CodingQuestion(
            instruction: "Read user input into $type variable '$varName' in C++.",
            codeLines: [
              [CodeSegment.text("$type $varName;")],
              [CodeSegment.text("std::"), CodeSegment.slot("s0"), CodeSegment.text(" >> "), CodeSegment.slot("s1"), CodeSegment.text(";")]
            ],
            choices: _shuffle(["cin", varName, "cout", "endl", "get", "input"], rand),
            correctAnswers: {"s0": "cin", "s1": varName},
          );
        }

      case 1: // Variables & Data Types
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Declare an integer variable named 'age' and set it to 21.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.slot("s1"),
                CodeSegment.text(" = "),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["int", "age", "21", "double", "float", "var"], rand),
            correctAnswers: {"s0": "int", "s1": "age", "s2": "21"},
          );
        } else {
          final constPairs = [
            ["PI", "double", "3.14"],
            ["MAX_HEALTH", "int", "100"],
            ["GRAVITY", "float", "9.8"],
            ["LIVES", "int", "3"],
            ["RATIO", "double", "1.61"],
          ];
          final cp = constPairs[(qIndex ~/ 2) % constPairs.length];
          final cName = cp[0];
          final cType = cp[1];
          final cVal = cp[2];
          return CodingQuestion(
            instruction: "Declare a constant $cType variable named '$cName' with value $cVal.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" $cName = "),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["const", cType, cVal, "int", "float", "let"], rand),
            correctAnswers: {"s0": "const", "s1": cType, "s2": cVal},
          );
        }

      case 2: // Math Operations
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Divide double variable 'x' by double variable 'y'.",
            codeLines: [
              [
                CodeSegment.text("double x = 10.0;"),
              ],
              [
                CodeSegment.text("double y = 4.0;"),
              ],
              [
                CodeSegment.text("double result = x "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" y;"),
              ]
            ],
            choices: _shuffle(["/", "%", "*", "+", "-", "div"], rand),
            correctAnswers: {"s0": "/"},
          );
        } else {
          final mathTriples = [
            ["rem", "10", "3"],
            ["mod", "25", "4"],
            ["result", "17", "5"],
            ["remainder", "9", "2"],
            ["leftover", "100", "9"],
          ];
          final mt = mathTriples[(qIndex ~/ 2) % mathTriples.length];
          final rVar = mt[0];
          final v1 = mt[1];
          final v2 = mt[2];
          return CodingQuestion(
            instruction: "Calculate remainder of $v1 divided by $v2 in C++.",
            codeLines: [
              [CodeSegment.text("int $rVar = $v1 "), CodeSegment.slot("s0"), CodeSegment.text(" $v2;")]
            ],
            choices: _shuffle(["%", "/", "*", "+", "-", "rem"], rand),
            correctAnswers: {"s0": "%"},
          );
        }

      case 3: // String Handling
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Include string library and declare string 's' with value \"hi\".",
            codeLines: [
              [
                CodeSegment.text("#include <"),
                CodeSegment.slot("s0"),
                CodeSegment.text(">"),
              ],
              [
                CodeSegment.text("std::"),
                CodeSegment.slot("s1"),
                CodeSegment.text(" s = "),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["string", "string", "\"hi\"", "iostream", "text", "char*"], rand),
            correctAnswers: {"s0": "string", "s1": "string", "s2": "\"hi\""},
          );
        } else {
          final strPairs = [
            ["s", "\"hello\"", "len"],
            ["name", "\"Codu\"", "nameLength"],
            ["text", "\"C++\"", "sizeVal"],
            ["word", "\"programming\"", "wLen"],
            ["msg", "\"Welcome\"", "msgSize"],
          ];
          final sp = strPairs[(qIndex ~/ 2) % strPairs.length];
          final sVar = sp[0];
          final sVal = sp[1];
          final lVar = sp[2];
          return CodingQuestion(
            instruction: "Get the length of C++ std::string '$sVar'.",
            codeLines: [
              [CodeSegment.text("std::string $sVar = $sVal;")],
              [CodeSegment.text("int $lVar = $sVar."), CodeSegment.slot("s0"), CodeSegment.slot("s1"), CodeSegment.slot("s2"), CodeSegment.text(";")]
            ],
            choices: _shuffle(["length", "(", ")", "size", "len", "count"], rand),
            correctAnswers: {"s0": "length", "s1": "(", "s2": ")"},
          );
        }

      case 4: // Simple Conditions (If)
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Complete the if check for pointer not being null.",
            codeLines: [
              [
                CodeSegment.text("int* ptr = nullptr;"),
              ],
              [
                CodeSegment.text("if (ptr "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" nullptr) {"),
              ],
              [
                CodeSegment.text("    // ..."),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["!=", "==", "=", "&&", "||", "is"], rand),
            correctAnswers: {"s0": "!="},
          );
        } else {
          final posPairs = [
            ["num", "0", "positive"],
            ["score", "50", "pass"],
            ["speed", "100", "overSpeed"],
            ["lives", "0", "alive"],
            ["temp", "37", "fever"],
          ];
          final pp = posPairs[(qIndex ~/ 2) % posPairs.length];
          final varName = pp[0];
          final limit = pp[1];
          final comment = pp[2];
          return CodingQuestion(
            instruction: "Check if integer '$varName' is greater than $limit.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ($varName "), CodeSegment.slot("s1"), CodeSegment.text(" $limit) {")],
              [CodeSegment.text("    // $comment")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["if", ">", "<", "==", "else", "then"], rand),
            correctAnswers: {"s0": "if", "s1": ">"},
          );
        }

      case 5: // Complex Conditions (If-Else)
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Fill in the if-else block logic in C++.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" (val > 100) {"),
              ],
              [
                CodeSegment.text("    std::cout << \"Large\";"),
              ],
              [
                CodeSegment.text("} "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" {"),
              ],
              [
                CodeSegment.text("    std::cout << \"Small\";"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["if", "else", "then", "elif", "else if"], rand),
            correctAnswers: {"s0": "if", "s1": "else"},
          );
        } else {
          final condPairs = [
            ["score", "50", "Pass", "Fail"],
            ["age", "18", "Adult", "Minor"],
            ["speed", "70", "Fast", "Slow"],
            ["temp", "32", "Hot", "Cold"],
            ["points", "10", "Win", "Lose"],
          ];
          final cp = condPairs[(qIndex ~/ 2) % condPairs.length];
          final varName = cp[0];
          final threshold = cp[1];
          final msg1 = cp[2];
          final msg2 = cp[3];
          return CodingQuestion(
            instruction: "Fill in if-else C++ syntax. If $varName is >= $threshold print $msg1, else $msg2.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ($varName >= $threshold) {")],
              [CodeSegment.text("    std::cout << \"$msg1\";")],
              [CodeSegment.text("} "), CodeSegment.slot("s1"), CodeSegment.text(" {")],
              [CodeSegment.text("    std::cout << \"$msg2\";")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["if", "else", "elif", "then", "otherwise"], rand),
            correctAnswers: {"s0": "if", "s1": "else"},
          );
        }

      case 6: // Logical Operators
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Check if 'hasKey' AND 'knowsPasscode' are true in C++.",
            codeLines: [
              [
                CodeSegment.text("if (hasKey "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" knowsPasscode) {"),
              ],
              [
                CodeSegment.text("    std::cout << \"Access\";"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["&&", "||", "and", "or", "&", "|"], rand),
            correctAnswers: {"s0": "&&"},
          );
        } else {
          final rangePairs = [
            ["score", "0", "100", "Invalid"],
            ["temp", "0", "40", "Extreme"],
            ["speed", "20", "120", "Alert"],
            ["height", "100", "200", "Out of bounds"],
            ["lives", "1", "5", "Invalid lives"],
          ];
          final rp = rangePairs[(qIndex ~/ 2) % rangePairs.length];
          final varName = rp[0];
          final lower = rp[1];
          final upper = rp[2];
          final msg = rp[3];
          return CodingQuestion(
            instruction: "Check if $varName is less than $lower OR greater than $upper ($msg range).",
            codeLines: [
              [CodeSegment.text("if ($varName < $lower "), CodeSegment.slot("s0"), CodeSegment.text(" $varName > $upper) {")],
              [CodeSegment.text("    std::cout << \"$msg\";")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["||", "&&", "or", "and", "|", "&"], rand),
            correctAnswers: {"s0": "||"},
          );
        }

      case 7: // While Loops
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Write a while loop conditional in C++.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" (index < 10) {"),
              ],
              [
                CodeSegment.text("    index"),
                CodeSegment.slot("s1"),
                CodeSegment.text(";"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["while", "++", "for", "+=", "--", "do"], rand),
            correctAnswers: {"s0": "while", "s1": "++"},
          );
        } else {
          final loopActions = ["doSomething", "updateGame", "listenInput", "checkState", "refreshUI"];
          final action = loopActions[(qIndex ~/ 2) % loopActions.length];
          return CodingQuestion(
            instruction: "Create an infinite loop or condition that stays active in C++.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ("), CodeSegment.slot("s1"), CodeSegment.text(") {")],
              [CodeSegment.text("    $action();")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["while", "true", "false", "for", "if", "1"], rand),
            correctAnswers: {"s0": "while", "s1": "true"},
          );
        }

      case 8: // For Loops
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Fill in the increment part of a standard for loop.",
            codeLines: [
              [
                CodeSegment.text("for (int i = 0; i < 5; "),
                CodeSegment.slot("s0"),
                CodeSegment.text(") {"),
              ],
              [
                CodeSegment.text("    std::cout << i;"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["i++", "++i", "i = i + 1", "i+1", "i--"], rand),
            correctAnswers: {"s0": "i++"},
          );
        } else {
          final loopVars = [
            ["N", "process"],
            ["limit", "render"],
            ["size", "update"],
            ["maxVal", "calculate"],
            ["count", "printVal"],
          ];
          final lv = loopVars[(qIndex ~/ 2) % loopVars.length];
          final limitVar = lv[0];
          final fnName = lv[1];
          return CodingQuestion(
            instruction: "Declare standard C++ for loop counting from 0 up to less than $limitVar.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" (int i = 0; i < "), CodeSegment.slot("s1"), CodeSegment.text("; i++) {")],
              [CodeSegment.text("    $fnName(i);")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["for", limitVar, "while", "N", "each", "count"], rand),
            correctAnswers: {"s0": "for", "s1": limitVar},
          );
        }

      case 9: // Collections / Arrays
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Add value 42 to the end of a std::vector.",
            codeLines: [
              [
                CodeSegment.text("std::vector<int> vec;"),
              ],
              [
                CodeSegment.text("vec."),
                CodeSegment.slot("s0"),
                CodeSegment.text("("),
                CodeSegment.slot("s1"),
                CodeSegment.text(");"),
              ]
            ],
            choices: _shuffle(["push_back", "42", "add", "insert", "append", "pop_back"], rand),
            correctAnswers: {"s0": "push_back", "s1": "42"},
          );
        } else {
          final vecPairs = [
            ["vec", "int", "{1, 2}", "sz"],
            ["scores", "double", "{8.5, 9.0, 7.2}", "numScores"],
            ["names", "std::string", "{\"Bob\", \"Ann\"}", "vectorSize"],
            ["prices", "float", "{1.99, 2.50}", "listSize"],
            ["flags", "bool", "{true, false}", "count"],
          ];
          final vp = vecPairs[(qIndex ~/ 2) % vecPairs.length];
          final vVar = vp[0];
          final vType = vp[1];
          final vVal = vp[2];
          final sVar = vp[3];
          return CodingQuestion(
            instruction: "Get the size of std::vector '$vVar' in C++.",
            codeLines: [
              [CodeSegment.text("std::vector<$vType> $vVar = $vVal;")],
              [CodeSegment.text("int $sVar = $vVar."), CodeSegment.slot("s0"), CodeSegment.slot("s1"), CodeSegment.slot("s2"), CodeSegment.text(";")]
            ],
            choices: _shuffle(["size", "(", ")", "length", sVar, "count"], rand),
            correctAnswers: {"s0": "size", "s1": "(", "s2": ")"},
          );
        }

      default:
        return _defaultFallbackQuestion("C++", rand);
    }
  }

  // --- JAVA QUESTION GENERATION ---
  static CodingQuestion _generateJavaQuestion(int topic, int level, int qIndex, Random rand) {
    switch (topic) {
      case 0: // Output Basics
        if (qIndex % 2 == 0) {
          final messages = ["Hello Java", "Codu Rules", "OOP Java"];
          final msg = messages[qIndex % messages.length];
          return CodingQuestion(
            instruction: "Complete the Java code to print \"$msg\" to the console.",
            codeLines: [
              [
                CodeSegment.text("System."),
                CodeSegment.slot("s0"),
                CodeSegment.text("."),
                CodeSegment.slot("s1"),
                CodeSegment.text("("),
                CodeSegment.slot("s2"),
                CodeSegment.text(");"),
              ]
            ],
            choices: _shuffle(["out", "println", "\"$msg\"", "print", "err", "format"], rand),
            correctAnswers: {"s0": "out", "s1": "println", "s2": "\"$msg\""},
          );
        } else {
          final charPairs = [
            ["\"A\"", "\"B\""],
            ["\"X\"", "\"Y\""],
            ["\"1\"", "\"2\""],
            ["\"hello\"", "\"world\""],
            ["\"yes\"", "\"no\""],
          ];
          final cp = charPairs[(qIndex ~/ 2) % charPairs.length];
          final c1 = cp[0];
          final c2 = cp[1];
          return CodingQuestion(
            instruction: "Complete code to print $c1 and $c2 on separate lines in Java.",
            codeLines: [
              [CodeSegment.text("System.out."), CodeSegment.slot("s0"), CodeSegment.text("($c1);")],
              [CodeSegment.text("System.out."), CodeSegment.slot("s1"), CodeSegment.text("($c2);")]
            ],
            choices: _shuffle(["println", "println", "print", "out", "show", "log"], rand),
            correctAnswers: {"s0": "println", "s1": "println"},
          );
        }

      case 1: // Variables & Data Types
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Declare a Java string variable named 'name' with value \"Bob\".",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.slot("s1"),
                CodeSegment.text(" = "),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["String", "name", "\"Bob\"", "string", "var", "char"], rand),
            correctAnswers: {"s0": "String", "s1": "name", "s2": "\"Bob\""},
          );
        } else {
          final boolPairs = [
            ["isValid", "true"],
            ["isRunning", "false"],
            ["hasAccess", "true"],
            ["isEmpty", "false"],
            ["canPlay", "true"],
          ];
          final bp = boolPairs[(qIndex ~/ 2) % boolPairs.length];
          final bVar = bp[0];
          final bVal = bp[1];
          return CodingQuestion(
            instruction: "Declare a boolean variable '$bVar' set to $bVal in Java.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.slot("s1"),
                CodeSegment.text(" = "),
                CodeSegment.slot("s2"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["boolean", bVar, bVal, "Boolean", "bool", "false"], rand),
            correctAnswers: {"s0": "boolean", "s1": bVar, "s2": bVal},
          );
        }

      case 2: // Math Operations
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Perform mathematical modulo division in Java.",
            codeLines: [
              [
                CodeSegment.text("int value = 11;"),
              ],
              [
                CodeSegment.text("int mod = value "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" 3; // Should equal 2"),
              ]
            ],
            choices: _shuffle(["%", "/", "*", "+", "-", "mod"], rand),
            correctAnswers: {"s0": "%"},
          );
        } else {
          final divPairs = [
            ["total", "20", "half", "2"],
            ["points", "100", "quarter", "4"],
            ["count", "50", "tenth", "10"],
            ["sum", "80", "divided", "8"],
            ["value", "15", "third", "3"],
          ];
          final dp = divPairs[(qIndex ~/ 2) % divPairs.length];
          final tVar = dp[0];
          final tVal = dp[1];
          final hVar = dp[2];
          final dVal = dp[3];
          return CodingQuestion(
            instruction: "Perform integer division of '$tVar' by $dVal in Java.",
            codeLines: [
              [CodeSegment.text("int $tVar = $tVal;")],
              [CodeSegment.text("int $hVar = $tVar "), CodeSegment.slot("s0"), CodeSegment.text(" $dVal;")]
            ],
            choices: _shuffle(["/", "%", "*", "+", "-", "div"], rand),
            correctAnswers: {"s0": "/"},
          );
        }

      case 3: // String Handling
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Find the length of string 'str' in Java.",
            codeLines: [
              [
                CodeSegment.text("String str = \"Java\";"),
              ],
              [
                CodeSegment.text("int len = str."),
                CodeSegment.slot("s0"),
                CodeSegment.text(";"),
              ]
            ],
            choices: _shuffle(["length()", "length", "size()", "count", "size"], rand),
            correctAnswers: {"s0": "length()"},
          );
        } else {
          final concatPairs = [
            ["a", "\"Hi \"", "b", "\"Codu\"", "res"],
            ["first", "\"Hello \"", "second", "\"World\"", "full"],
            ["str1", "\"Java \"", "str2", "\"Rules\"", "msg"],
            ["greeting", "\"Welcome \"", "name", "\"User\"", "text"],
            ["prefix", "\"Level \"", "suffix", "\"Up\"", "output"],
          ];
          final cp = concatPairs[(qIndex ~/ 2) % concatPairs.length];
          final s1Name = cp[0];
          final s1Val = cp[1];
          final s2Name = cp[2];
          final s2Val = cp[3];
          final resName = cp[4];
          return CodingQuestion(
            instruction: "Concatenate string '$s1Name' and '$s2Name' in Java.",
            codeLines: [
              [CodeSegment.text("String $s1Name = $s1Val;")],
              [CodeSegment.text("String $s2Name = $s2Val;")],
              [CodeSegment.text("String $resName = $s1Name "), CodeSegment.slot("s0"), CodeSegment.text(" $s2Name;")]
            ],
            choices: _shuffle(["+", "concat", "add", "and", "&", resName], rand),
            correctAnswers: {"s0": "+"},
          );
        }

      case 4: // Simple Conditions (If)
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Check if variable 'score' is greater than or equal to 50.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" (score "),
                CodeSegment.slot("s1"),
                CodeSegment.text(" 50) {"),
              ],
              [
                CodeSegment.text("    System.out.println(\"Pass\");"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["if", ">=", ">", "==", "when", "elif"], rand),
            correctAnswers: {"s0": "if", "s1": ">="},
          );
        } else {
          final refNames = ["obj", "data", "node", "user", "connection"];
          final refName = refNames[(qIndex ~/ 2) % refNames.length];
          return CodingQuestion(
            instruction: "Check if reference '$refName' is null in Java.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ($refName "), CodeSegment.slot("s1"), CodeSegment.text(" null) {")],
              [CodeSegment.text("    // is null")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["if", "==", "!=", "=", "is", "null"], rand),
            correctAnswers: {"s0": "if", "s1": "=="},
          );
        }

      case 5: // Complex Conditions (If-Else)
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Write the else clause in Java.",
            codeLines: [
              [
                CodeSegment.text("if (flag) {"),
              ],
              [
                CodeSegment.text("    doSomething();"),
              ],
              [
                CodeSegment.text("} "),
                CodeSegment.slot("s0"),
                CodeSegment.text(" {"),
              ],
              [
                CodeSegment.text("    doOtherwise();"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["else", "otherwise", "then", "catch", "else if"], rand),
            correctAnswers: {"s0": "else"},
          );
        } else {
          final gradePairs = [
            ["score", "90", "A", "B"],
            ["average", "75", "Pass", "Fail"],
            ["age", "18", "Adult", "Minor"],
            ["speed", "60", "Fast", "Slow"],
            ["level", "10", "Pro", "Rookie"],
          ];
          final gp = gradePairs[(qIndex ~/ 2) % gradePairs.length];
          final varName = gp[0];
          final threshold = gp[1];
          final msg1 = gp[2];
          final msg2 = gp[3];
          return CodingQuestion(
            instruction: "Complete Java if-else block. If $varName > $threshold print $msg1, else print $msg2.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ($varName > $threshold) {")],
              [CodeSegment.text("    System.out.println(\"$msg1\");")],
              [CodeSegment.text("} "), CodeSegment.slot("s1"), CodeSegment.text(" {")],
              [CodeSegment.text("    System.out.println(\"$msg2\");")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["if", "else", "elif", "then", "otherwise"], rand),
            correctAnswers: {"s0": "if", "s1": "else"},
          );
        }

      case 6: // Logical Operators
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Write a negation (logical NOT) condition in Java.",
            codeLines: [
              [
                CodeSegment.text("boolean isLocked = true;"),
              ],
              [
                CodeSegment.text("if ("),
                CodeSegment.slot("s0"),
                CodeSegment.text("isLocked) {"),
              ],
              [
                CodeSegment.text("    openDoor();"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["!", "not", "~", "==", "&&", "||"], rand),
            correctAnswers: {"s0": "!"},
          );
        } else {
          final authPairs = [
            ["hasPerm", "isVerified", "grantAccess"],
            ["isOnline", "hasSubscription", "playVideo"],
            ["isReady", "hasKey", "startGame"],
            ["isValid", "isApproved", "submitForm"],
            ["hasPoints", "levelFinished", "unlockAchievement"],
          ];
          final ap = authPairs[(qIndex ~/ 2) % authPairs.length];
          final v1 = ap[0];
          final v2 = ap[1];
          final action = ap[2];
          return CodingQuestion(
            instruction: "Check if user has $v1 AND is $v2 in Java.",
            codeLines: [
              [CodeSegment.text("if ($v1 "), CodeSegment.slot("s0"), CodeSegment.text(" $v2) {")],
              [CodeSegment.text("    $action();")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["&&", "||", "and", "or", "&", "|"], rand),
            correctAnswers: {"s0": "&&"},
          );
        }

      case 7: // While Loops
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Complete a simple Java while loop.",
            codeLines: [
              [
                CodeSegment.slot("s0"),
                CodeSegment.text(" (count > 0) {"),
              ],
              [
                CodeSegment.text("    count"),
                CodeSegment.slot("s1"),
                CodeSegment.text(";"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["while", "--", "++", "for", "loop", "if"], rand),
            correctAnswers: {"s0": "while", "s1": "--"},
          );
        } else {
          final streamPairs = [
            ["stream", "hasMore", "readData"],
            ["reader", "ready", "readLine"],
            ["iterator", "hasNext", "next"],
            ["scanner", "hasNextLine", "nextLine"],
            ["parser", "canRead", "parseNode"],
          ];
          final sp = streamPairs[(qIndex ~/ 2) % streamPairs.length];
          final objName = sp[0];
          final checkFn = sp[1];
          final actionFn = sp[2];
          return CodingQuestion(
            instruction: "Complete loop checking if $objName has data.",
            codeLines: [
              [CodeSegment.slot("s0"), CodeSegment.text(" ($objName.$checkFn()) {")],
              [CodeSegment.text("    $actionFn();")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["while", "for", "if", "loop", objName, "true"], rand),
            correctAnswers: {"s0": "while"},
          );
        }

      case 8: // For Loops
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Complete a standard loop initialization in Java.",
            codeLines: [
              [
                CodeSegment.text("for ("),
                CodeSegment.slot("s0"),
                CodeSegment.text(" i = 0; i < 10; i++) {"),
              ],
              [
                CodeSegment.text("    System.out.println(i);"),
              ],
              [
                CodeSegment.text("}"),
              ]
            ],
            choices: _shuffle(["int", "float", "double", "var", "let", "Integer"], rand),
            correctAnswers: {"s0": "int"},
          );
        } else {
          final forLoopTriples = [
            ["i", "5", "doWork"],
            ["j", "10", "updatePhysics"],
            ["k", "8", "renderFrame"],
            ["idx", "3", "processItem"],
            ["count", "12", "printCount"],
          ];
          final flt = forLoopTriples[(qIndex ~/ 2) % forLoopTriples.length];
          final loopVar = flt[0];
          final countVal = flt[1];
          final fnName = flt[2];
          return CodingQuestion(
            instruction: "Fill in the range condition for a loop to run exactly $countVal times (0 to ${int.parse(countVal) - 1}).",
            codeLines: [
              [CodeSegment.text("for (int $loopVar = 0; $loopVar "), CodeSegment.slot("s0"), CodeSegment.text(" $countVal; $loopVar++) {")],
              [CodeSegment.text("    $fnName();")],
              [CodeSegment.text("}")]
            ],
            choices: _shuffle(["<", "<=", ">", "==", "!=", countVal], rand),
            correctAnswers: {"s0": "<"},
          );
        }

      case 9: // Collections / Arrays
        if (qIndex % 2 == 0) {
          return CodingQuestion(
            instruction: "Add value \"Java\" to an ArrayList in Java.",
            codeLines: [
              [
                CodeSegment.text("ArrayList<String> list = new ArrayList<>();"),
              ],
              [
                CodeSegment.text("list."),
                CodeSegment.slot("s0"),
                CodeSegment.text("("),
                CodeSegment.slot("s1"),
                CodeSegment.text(");"),
              ]
            ],
            choices: _shuffle(["add", "\"Java\"", "push", "append", "insert", "list"], rand),
            correctAnswers: {"s0": "add", "s1": "\"Java\""},
          );
        } else {
          final listPairs = [
            ["list", "Integer", "sz"],
            ["names", "String", "totalNames"],
            ["scores", "Double", "numScores"],
            ["users", "User", "userCount"],
            ["items", "Item", "itemSize"],
          ];
          final lp = listPairs[(qIndex ~/ 2) % listPairs.length];
          final listName = lp[0];
          final listType = lp[1];
          final sizeVar = lp[2];
          return CodingQuestion(
            instruction: "Get the size of an ArrayList in Java.",
            codeLines: [
              [CodeSegment.text("ArrayList<$listType> $listName = new ArrayList<>();")],
              [CodeSegment.text("int $sizeVar = $listName."), CodeSegment.slot("s0"), CodeSegment.slot("s1"), CodeSegment.slot("s2"), CodeSegment.text(";")]
            ],
            choices: _shuffle(["size", "(", ")", "length", "count", sizeVar], rand),
            correctAnswers: {"s0": "size", "s1": "(", "s2": ")"},
          );
        }

      default:
        return _defaultFallbackQuestion("Java", rand);
    }
  }

  // Helper shuffle to randomise choices
  static List<String> _shuffle(List<String> items, Random rand) {
    List<String> copy = List.from(items);
    for (int i = copy.length - 1; i > 0; i--) {
      int j = rand.nextInt(i + 1);
      String temp = copy[i];
      copy[i] = copy[j];
      copy[j] = temp;
    }
    return copy;
  }

  // Fallback question
  static CodingQuestion _defaultFallbackQuestion(String lang, Random rand) {
    return CodingQuestion(
      instruction: "Complete the $lang comment.",
      codeLines: [
        [
          CodeSegment.slot("s0"),
          CodeSegment.text(" This is a comment"),
        ]
      ],
      choices: _shuffle(["#", "//", "/*", "<!--", "--"], rand),
      correctAnswers: {"s0": lang == 'Python' ? "#" : "//"},
    );
  }
}
