import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const TypingTesterApp());
}

class TypingTesterApp extends StatelessWidget {
  const TypingTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speed Typing Test',
      theme: ThemeData(
        primarySwatch: Colors.amber, 
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const TypingTestScreen(),
    );
  }
}

class TypingTestScreen extends StatefulWidget {
  const TypingTestScreen({super.key});

  @override
  State<TypingTestScreen> createState() => _TypingTestScreenState();
}

class _TypingTestScreenState extends State<TypingTestScreen> {
  // --- Game Data: Difficulty and Paragraphs ---
  final Map<String, List<String>> _difficultyParagraphs = const {
    'Easy': [
      "The sun sets fast over the quiet blue lake. I often read books by the window when it rains. We must try to keep the garden neat and clean. Apples and bananas are good for a morning snack.",
      "The quick brown fox jumped over the lazy dog. Programming is a useful skill to learn today. Simple sentences are better for speed tests. Click the button to start the timer right now.",
    ],
    'Medium': [
      "Flutter is an open-source UI software development kit created by Google. It is used to develop cross-platform applications from a single codebase for any screen. The framework allows developers to build natively compiled apps for mobile, web, and desktop.",
      "Dart is a client-optimized language for fast apps on any platform. Its core focus is on speed and productivity, compiling to native machine code. Widgets are the central concept to Flutter development, making up the entire UI.",
      "State management in any mobile application is a critical concept; techniques like Provider, BLoC, and Riverpod efficiently update the UI. The World Wide Web was first created by Tim Berners-Lee in the late nineteen-eighties.",
    ],
    'Hard': [
      "The labyrinthine complexity of asynchronous operations demands careful handling; Future, async, and await are crucial for maintaining a non-blocking user interface in high-performance Dart applications.",
      "For a seasoned programmer, optimizing code execution speed often involves micro-level adjustments, analyzing garbage collection cycles, and minimizing unnecessary state changes, which are intrinsically difficult tasks.",
      "A rigorous analysis of semantic versioning (Major.Minor.Patch) is mandatory before deploying critical updates; otherwise, unintended dependency conflicts can cascade throughout the entire development ecosystem.",
    ],
  };

  late String _currentParagraph;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  // --- Timer Variables ---
  late Timer _timer;
  late int _timeLeft;
  bool _isRunning = false;

  // --- Game State & Results ---
  String _selectedDifficulty = 'Medium'; // Default difficulty
  double _wpm = 0.0;
  double _accuracy = 0.0;
  int _correctChars = 0;
  int _incorrectChars = 0;
  
  final Map<String, int> _timerOptions = const {
    '30 sec': 30,
    '1 min': 60,
  };
  late int _selectedDurationSeconds;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _selectedDurationSeconds = _timerOptions['1 min']!;
    _initializeTest();
  }

  void _initializeTest() {
    // Stop any running timer
    if (_isRunning) _timer.cancel();

    // Get the list of paragraphs for the current difficulty
    final List<String> paragraphsForDifficulty = _difficultyParagraphs[_selectedDifficulty]!;

    setState(() {
      // Select a random paragraph from the chosen difficulty list
      _currentParagraph = paragraphsForDifficulty[Random().nextInt(paragraphsForDifficulty.length)];
      _textController.clear();
      _timeLeft = _selectedDurationSeconds;
      _isRunning = false;
      _wpm = 0.0;
      _accuracy = 100.0;
      _correctChars = 0;
      _incorrectChars = 0;
    });

    Future.delayed(Duration.zero, () => _focusNode.requestFocus());
  }

  void _startTimer() {
    if (_isRunning) return;

    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
          _calculateResults();
        });
      } else {
        _timer.cancel();
        _isRunning = false;
        _calculateResults(finalResult: true);
      }
    });
  }

  void _calculateResults({bool finalResult = false}) {
    if (!_isRunning && !finalResult) return;

    String typedText = _textController.text;
    String sourceText = _currentParagraph;
    
    int totalTypedChars = typedText.length;
    _correctChars = 0;
    _incorrectChars = 0;

    for (int i = 0; i < totalTypedChars; i++) {
      if (i < sourceText.length && typedText[i] == sourceText[i]) {
        _correctChars++;
      } else {
        _incorrectChars++;
      }
    }

    if (totalTypedChars > 0) {
      int timeElapsed = _selectedDurationSeconds - _timeLeft;
      double minutes = timeElapsed / 60.0;
      
      if (minutes > 0) {
        _wpm = (_correctChars / 5) / minutes;
      } else {
        _wpm = 0.0;
      }

      _accuracy = (_correctChars / totalTypedChars) * 100.0;
    } else {
      _wpm = 0.0;
      _accuracy = 100.0;
    }
  }

  TextSpan _highlightText(String source, String typed) {
    List<TextSpan> spans = [];
    for (int i = 0; i < source.length; i++) {
      Color color;
      if (i < typed.length) {
        if (source[i] == typed[i]) {
          color = Colors.lightGreenAccent.shade400; 
        } else {
          color = Colors.red.shade600; 
        }
      } else {
        color = Colors.grey.shade600;
      }

      spans.add(TextSpan(
        text: source[i],
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
      ));
    }
    return TextSpan(children: spans);
  }

  @override
  void dispose() {
    if (_isRunning) _timer.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String timeDisplay = 
      '${(_timeLeft ~/ 60).toString().padLeft(2, '0')}:${(_timeLeft % 60).toString().padLeft(2, '0')}';
      
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Speed Test ⏱'),
        centerTitle: true,
        actions: [
          // Difficulty Selector
          DropdownButton<String>(
            value: _selectedDifficulty,
            hint: Text("Difficulty", style: TextStyle(color: Colors.amber.shade200)),
            items: _difficultyParagraphs.keys.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.amber)),
              );
            }).toList(),
            onChanged: _isRunning ? null : (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDifficulty = newValue;
                  _initializeTest();
                });
              }
            },
            dropdownColor: Colors.grey.shade900,
            style: const TextStyle(color: Colors.amber, fontSize: 16),
            iconEnabledColor: Colors.amber,
          ),
          
          const SizedBox(width: 10),
          
          // Timer Selector
          DropdownButton<int>(
            value: _selectedDurationSeconds,
            hint: Text("Select Time", style: TextStyle(color: Colors.amber.shade200)), 
            items: _timerOptions.entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.value,
                child: Text(entry.key, style: const TextStyle(color: Colors.amber)),
              );
            }).toList(),
            onChanged: _isRunning ? null : (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDurationSeconds = newValue;
                  _initializeTest();
                });
              }
            },
            dropdownColor: Colors.grey.shade900,
            style: const TextStyle(color: Colors.amber, fontSize: 16),
            iconEnabledColor: Colors.amber,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Timer & Results Display ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Time Left', timeDisplay, Colors.amber.shade300, unit: 'm'), 
                  _buildStatCard('WPM', _wpm.toStringAsFixed(1), Colors.deepOrange.shade300), 
                  _buildStatCard('Accuracy', '${_accuracy.toStringAsFixed(1)}%', Colors.yellow.shade300), 
                  _buildStatCard('Errors', _incorrectChars.toString(), Colors.red.shade400), 
                ],
              ),
              const SizedBox(height: 30),

              // --- Difficulty Label ---
              Center(
                child: Text(
                  'Difficulty: $_selectedDifficulty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber.shade400),
                ),
              ),
              const SizedBox(height: 10),

              // --- Paragraph Display Area ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 2), 
                ),
                child: RichText(
                  text: _highlightText(_currentParagraph, _textController.text),
                ),
              ),
              const SizedBox(height: 30),

              // --- Input Field ---
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: _timeLeft > 0,
                onChanged: (text) {
                  if (!_isRunning && text.isNotEmpty) {
                    _startTimer();
                  }
                  _calculateResults();
                },
                style: const TextStyle(fontSize: 18, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Start Typing Here...', 
                  labelStyle: TextStyle(color: Colors.amber.shade200),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  suffixIcon: _isRunning ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700)), 
                  ) : null,
                ),
                maxLines: null,
              ),
              const SizedBox(height: 30),

              // --- Reset Button ---
              ElevatedButton.icon(
                onPressed: _initializeTest,
                icon: const Icon(Icons.refresh),
                label: const Text('START NEW TEST', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, {String? unit}) {
    return Card(
      color: Colors.grey.shade800,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              unit == 'm' ? value : value + (unit ?? ''),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}