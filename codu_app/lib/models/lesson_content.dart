class LessonExplanation {
  final String title;
  final String description;
  final String codeExample;
  final String mascotExpression;

  const LessonExplanation({
    required this.title,
    required this.description,
    required this.codeExample,
    this.mascotExpression = 'assets/images/CoduExpression/codu thinking.svg',
  });
}

class LessonContentRepository {
  static LessonExplanation getExplanation(String subject, int levelNumber) {
    final int topicIndex = (levelNumber - 1) % 10;
    final String cleanSubject = subject;

    if (cleanSubject == 'Python') {
      return _getPythonExplanation(topicIndex);
    } else if (cleanSubject == 'Javascript') {
      return _getJSExplanation(topicIndex);
    } else if (cleanSubject == 'C++') {
      return _getCppExplanation(topicIndex);
    } else {
      return _getJavaExplanation(topicIndex);
    }
  }

  static LessonExplanation _getPythonExplanation(int topicIndex) {
    switch (topicIndex) {
      case 0:
        return const LessonExplanation(
          title: "Python Output Basics",
          description: "To print a message to the screen in Python, we use the print() function. The text must be enclosed inside quotes, like \"Hello\".",
          codeExample: "print(\"Hello, World!\")",
          mascotExpression: 'assets/images/CoduExpression/codu hi.svg',
        );
      case 1:
        return const LessonExplanation(
          title: "Python Variables",
          description: "Variables store data values. In Python, you create a variable by giving it a name and assigning a value using the '=' sign.",
          codeExample: "x = 5\nname = \"Codu\"",
        );
      case 2:
        return const LessonExplanation(
          title: "Python Math Operations",
          description: "Python uses standard symbols for math: '+' for addition, '-' for subtraction, '*' for multiplication, and '/' for division.",
          codeExample: "sum = 10 + 5\ndouble_x = x * 2",
        );
      case 3:
        return const LessonExplanation(
          title: "Python String Handling",
          description: "You can join two strings together using the '+' operator. This is called string concatenation.",
          codeExample: "greeting = \"Hello \" + \"Codu\"\nprint(greeting)",
        );
      case 4:
        return const LessonExplanation(
          title: "Python If Statements",
          description: "Use 'if' to execute code only when a condition is true. The condition ends with a colon ':', and the code below it must be indented (4 spaces).",
          codeExample: "if score > 50:\n    print(\"You Win!\")",
        );
      case 5:
        return const LessonExplanation(
          title: "Python If-Else",
          description: "Use 'else' to define an alternative block of code that runs if the 'if' condition is false.",
          codeExample: "if hearts > 0:\n    print(\"Keep playing\")\nelse:\n    print(\"Game Over\")",
        );
      case 6:
        return const LessonExplanation(
          title: "Python Logical Operators",
          description: "Combine multiple conditions using: 'and' (both must be true), 'or' (at least one must be true), and 'not' (reverses the condition).",
          codeExample: "if score > 10 and lives > 0:\n    print(\"You are safe!\")",
        );
      case 7:
        return const LessonExplanation(
          title: "Python While Loops",
          description: "A while loop repeats a block of code as long as a condition is true.",
          codeExample: "while lives > 0:\n    play_game()\n    lives -= 1",
        );
      case 8:
        return const LessonExplanation(
          title: "Python For Loops",
          description: "A for loop iterates over a range of numbers or a collection. range(n) repeats the loop n times.",
          codeExample: "for i in range(5):\n    print(\"Repeat:\", i)",
        );
      case 9:
        return const LessonExplanation(
          title: "Python Lists",
          description: "Lists store multiple items in a single variable. They are defined using square brackets '[]' and are 0-indexed.",
          codeExample: "colors = [\"red\", \"blue\", \"green\"]\nprint(colors[0])",
        );
      default:
        return const LessonExplanation(
          title: "Python Basics",
          description: "Let's test your Python coding skills and see how many stars you can get!",
          codeExample: "# Ready to start?",
        );
    }
  }

  static LessonExplanation _getJSExplanation(int topicIndex) {
    switch (topicIndex) {
      case 0:
        return const LessonExplanation(
          title: "JavaScript Output Basics",
          description: "In JavaScript, we use console.log() to print messages to the developer console. The text must be enclosed inside quotes.",
          codeExample: "console.log(\"Hello, World!\");",
          mascotExpression: 'assets/images/CoduExpression/codu hi.svg',
        );
      case 1:
        return const LessonExplanation(
          title: "JavaScript Variables",
          description: "Use 'let' to declare variables that can change, and 'const' to declare constants (values that stay the same).",
          codeExample: "let score = 0;\nconst maxLives = 3;",
        );
      case 2:
        return const LessonExplanation(
          title: "JavaScript Math Operations",
          description: "JavaScript supports arithmetic operators: '+' (add), '-' (subtract), '*' (multiply), '/' (divide), and '%' (remainder).",
          codeExample: "let total = 10 + 5;\nlet double = x * 2;",
        );
      case 3:
        return const LessonExplanation(
          title: "JavaScript Strings",
          description: "You can combine strings using the '+' operator, or embed variables directly inside backticks using \${variable}.",
          codeExample: "let greeting = \"Hello \" + name;\nlet msg = `Score: \${score}`;",
        );
      case 4:
        return const LessonExplanation(
          title: "JavaScript If Statements",
          description: "An if statement executes code if a condition is true. The condition is wrapped in parentheses (), followed by curly braces {}.",
          codeExample: "if (score > 10) {\n  console.log(\"Victory!\");\n}",
        );
      case 5:
        return const LessonExplanation(
          title: "JavaScript If-Else",
          description: "Use 'else' to define a block of code that runs if the 'if' condition evaluates to false.",
          codeExample: "if (lives > 0) {\n  continueGame();\n} else {\n  gameOver();\n}",
        );
      case 6:
        return const LessonExplanation(
          title: "JavaScript Logical Operators",
          description: "Combine conditions with '&&' (logical AND), '||' (logical OR), and '!' (logical NOT).",
          codeExample: "if (isReady && score > 50) {\n  levelUp();\n}",
        );
      case 7:
        return const LessonExplanation(
          title: "JavaScript While Loops",
          description: "A while loop repeats a block of code as long as a condition evaluates to true.",
          codeExample: "while (lives > 0) {\n  playTurn();\n  lives--;\n}",
        );
      case 8:
        return const LessonExplanation(
          title: "JavaScript For Loops",
          description: "A for loop repeats code a specific number of times. It has initialization, condition, and increment statements.",
          codeExample: "for (let i = 0; i < 5; i++) {\n  console.log(i);\n}",
        );
      case 9:
        return const LessonExplanation(
          title: "JavaScript Arrays",
          description: "Arrays are list-like objects used to store multiple values in a single variable. They use square brackets '[]'.",
          codeExample: "let colors = [\"red\", \"blue\", \"green\"];\nconsole.log(colors[0]);",
        );
      default:
        return const LessonExplanation(
          title: "JavaScript Basics",
          description: "Let's test your JavaScript coding skills and see how many stars you can get!",
          codeExample: "// Ready to start?",
        );
    }
  }

  static LessonExplanation _getCppExplanation(int topicIndex) {
    switch (topicIndex) {
      case 0:
        return const LessonExplanation(
          title: "C++ Output Basics",
          description: "In C++, we use std::cout combined with the insertion operator '<<' to print output. Use std::endl to insert a new line.",
          codeExample: "#include <iostream>\nstd::cout << \"Hello, World!\" << std::endl;",
          mascotExpression: 'assets/images/CoduExpression/codu hi.svg',
        );
      case 1:
        return const LessonExplanation(
          title: "C++ Variables",
          description: "C++ is strongly typed. You must specify the type of variable: 'int' for integers, 'double' for decimals, and 'std::string' for text.",
          codeExample: "int score = 100;\nstd::string player = \"Codu\";",
        );
      case 2:
        return const LessonExplanation(
          title: "C++ Math Operations",
          description: "C++ uses standard math operators. Integer division drops the decimal, so use float or double types for precise divisions.",
          codeExample: "int sum = a + b;\nfloat avg = sum / 2.0;",
        );
      case 3:
        return const LessonExplanation(
          title: "C++ String Handling",
          description: "Include <string> to use strings. You can concatenate strings using the '+' operator.",
          codeExample: "std::string msg = \"Hello \" + name;\nstd::cout << msg;",
        );
      case 4:
        return const LessonExplanation(
          title: "C++ If Statements",
          description: "Use 'if' to test a condition. The block of code to run must be enclosed in curly braces {}.",
          codeExample: "if (score >= 100) {\n  std::cout << \"Winner!\";\n}",
        );
      case 5:
        return const LessonExplanation(
          title: "C++ If-Else",
          description: "Add an 'else' block to run code if the 'if' condition is false.",
          codeExample: "if (hp > 0) {\n  alive = true;\n} else {\n  alive = false;\n}",
        );
      case 6:
        return const LessonExplanation(
          title: "C++ Logical Operators",
          description: "Combine conditions with '&&' (logical AND), '||' (logical OR), and '!' (logical NOT).",
          codeExample: "if (hasKey && doorLocked) {\n  unlockDoor();\n}",
        );
      case 7:
        return const LessonExplanation(
          title: "C++ While Loops",
          description: "A while loop runs code repeatedly as long as the condition in parentheses remains true.",
          codeExample: "while (lives > 0) {\n  playGame();\n  lives--;\n}",
        );
      case 8:
        return const LessonExplanation(
          title: "C++ For Loops",
          description: "Use a for loop to repeat code a set number of times. It initializes a counter, checks a condition, and updates the counter.",
          codeExample: "for (int i = 0; i < 5; i++) {\n  std::cout << i << \"\\n\";\n}",
        );
      case 9:
        return const LessonExplanation(
          title: "C++ Arrays & Vectors",
          description: "Use std::vector (from <vector>) to store lists of values that can grow or shrink in size.",
          codeExample: "std::vector<int> scores = {10, 20, 30};\nstd::cout << scores[0];",
        );
      default:
        return const LessonExplanation(
          title: "C++ Basics",
          description: "Let's test your C++ coding skills and see how many stars you can get!",
          codeExample: "// Ready to start?",
        );
    }
  }

  static LessonExplanation _getJavaExplanation(int topicIndex) {
    switch (topicIndex) {
      case 0:
        return const LessonExplanation(
          title: "Java Output Basics",
          description: "In Java, we print output to the console using System.out.println() for a new line, or System.out.print() to print on the same line.",
          codeExample: "System.out.println(\"Hello, World!\");",
          mascotExpression: 'assets/images/CoduExpression/codu hi.svg',
        );
      case 1:
        return const LessonExplanation(
          title: "Java Variables",
          description: "Java is strongly typed. Declare variable types explicitly, such as 'int' for integers, 'double' for decimals, and 'String' for text.",
          codeExample: "int score = 0;\nString name = \"Codu\";",
        );
      case 2:
        return const LessonExplanation(
          title: "Java Math Operations",
          description: "Java supports math operations: '+', '-', '*', '/'. Cast integers to double to avoid integer division truncation.",
          codeExample: "int total = a + b;\ndouble percentage = (double) score / total * 100;",
        );
      case 3:
        return const LessonExplanation(
          title: "Java Strings",
          description: "Combine strings using '+'. Java strings are objects with helpful methods like .length() or .toLowerCase().",
          codeExample: "String greeting = \"Hi \" + name;\nSystem.out.println(greeting);",
        );
      case 4:
        return const LessonExplanation(
          title: "Java If Statements",
          description: "An if statement tests a condition in parentheses, and runs the block inside {} if it is true.",
          codeExample: "if (score > 100) {\n  System.out.println(\"You passed!\");\n}",
        );
      case 5:
        return const LessonExplanation(
          title: "Java If-Else",
          description: "Use 'else' to perform an alternative action when the 'if' condition is false.",
          codeExample: "if (health > 0) {\n  System.out.println(\"Playing\");\n} else {\n  System.out.println(\"Dead\");\n}",
        );
      case 6:
        return const LessonExplanation(
          title: "Java Logical Operators",
          description: "Use '&&' (AND), '||' (OR), and '!' (NOT) to build complex conditions.",
          codeExample: "if (score >= 50 && lives > 0) {\n  System.out.println(\"Next level\");\n}",
        );
      case 7:
        return const LessonExplanation(
          title: "Java While Loops",
          description: "A while loop checks a condition first, then runs the block of code, repeating as long as the condition is true.",
          codeExample: "while (lives > 0) {\n  playGame();\n  lives--;\n}",
        );
      case 8:
        return const LessonExplanation(
          title: "Java For Loops",
          description: "Use a for loop to iterate a defined number of times. It consists of initialization, condition, and increment.",
          codeExample: "for (int i = 0; i < 5; i++) {\n  System.out.println(i);\n}",
        );
      case 9:
        return const LessonExplanation(
          title: "Java Arrays & ArrayLists",
          description: "Java arrays have a fixed size. Use ArrayList for a dynamic list that can grow and shrink in size.",
          codeExample: "int[] numbers = {1, 2, 3};\nArrayList<String> list = new ArrayList<>();",
        );
      default:
        return const LessonExplanation(
          title: "Java Basics",
          description: "Let's test your Java coding skills and see how many stars you can get!",
          codeExample: "// Ready to start?",
        );
    }
  }
}
