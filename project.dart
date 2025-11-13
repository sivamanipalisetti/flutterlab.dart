import 'package:flutter/material.dart';

void main() => runApp(const SOSGameApp());

class SOSGameApp extends StatelessWidget {
  const SOSGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SOSGame(),
    );
  }
}

class SOSGame extends StatefulWidget {
  const SOSGame({super.key});

  @override
  State<SOSGame> createState() => _SOSGameState();
}

class _SOSGameState extends State<SOSGame> {
  static const int boardSize = 3;
  List<List<String>> board =
      List.generate(boardSize, (_) => List.filled(boardSize, ''));

  bool player1Turn = true;
  bool moveInProgress = false; // prevents turn overlap
  int player1Score = 0;
  int player2Score = 0;

  void resetGame() {
    setState(() {
      board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
      player1Turn = true;
      player1Score = 0;
      player2Score = 0;
      moveInProgress = false;
    });
  }

  void makeMove(int r, int c, String letter) async {
    if (moveInProgress || board[r][c].isNotEmpty) return;
    setState(() => moveInProgress = true);

    setState(() {
      board[r][c] = letter;
      int earnedPoints = countPatterns(r, c);

      if (earnedPoints > 0) {
        if (player1Turn) {
          player1Score += earnedPoints;
        } else {
          player2Score += earnedPoints;
        }
      }

      // Always switch turn
      player1Turn = !player1Turn;
      moveInProgress = false;
    });
  }

  int countPatterns(int r, int c) {
    int count = 0;
    List<List<int>> dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1]
    ];

    for (var d in dirs) {
      int dr = d[0], dc = d[1];

      // check "SOS" both directions
      if (_checkSOS(r - dr, c - dc, r, c, r + dr, c + dc)) count++;

      // check 3 same letters
      if (_checkSame(r - dr, c - dc, r, c, r + dr, c + dc)) count++;
    }
    return count;
  }

  bool _checkSOS(int r1, int c1, int r2, int c2, int r3, int c3) {
    if (!_inBounds(r1, c1) || !_inBounds(r2, c2) || !_inBounds(r3, c3)) return false;
    return board[r1][c1] == 'S' && board[r2][c2] == 'O' && board[r3][c3] == 'S';
  }

  bool _checkSame(int r1, int c1, int r2, int c2, int r3, int c3) {
    if (!_inBounds(r1, c1) || !_inBounds(r2, c2) || !_inBounds(r3, c3)) return false;
    String a = board[r1][c1];
    String b = board[r2][c2];
    String cL = board[r3][c3];
    if (a.isEmpty || b.isEmpty || cL.isEmpty) return false;
    return a == b && b == cL;
  }

  bool _inBounds(int r, int c) => r >= 0 && r < boardSize && c >= 0 && c < boardSize;

  bool isBoardFull() => board.every((row) => row.every((cell) => cell.isNotEmpty));

  String get currentPlayer => player1Turn ? "Player 1 (Blue)" : "Player 2 (Red)";
  Color get currentColor => player1Turn ? Colors.blue : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Game (Turn Based)'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$currentPlayer's Turn",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: currentColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Score — Blue: $player1Score   Red: $player2Score',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          _buildBoard(),
          const SizedBox(height: 20),
          if (isBoardFull()) _buildResultSection(),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(boardSize, (r) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(boardSize, (c) {
            String cell = board[r][c];
            return GestureDetector(
              onTap: () {
                if (!moveInProgress && cell.isEmpty) _showLetterDialog(r, c);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.grey.shade200,
                ),
                child: Center(
                  child: Text(
                    cell,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: cell == 'S' ? Colors.blue : Colors.red,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  void _showLetterDialog(int r, int c) {
    if (moveInProgress) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${currentPlayer.split(' ')[0]} Choose Letter"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                makeMove(r, c, 'S');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('S'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                makeMove(r, c, 'O');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('O'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    String result;
    if (player1Score > player2Score) {
      result = "🎉 Player 1 (Blue) Wins!";
    } else if (player2Score > player1Score) {
      result = "🏆 Player 2 (Red) Wins!";
    } else {
      result = "🤝 It's a Draw!";
    }

    return Column(
      children: [
        Text(
          result,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: resetGame,
          icon: const Icon(Icons.refresh),
          label: const Text("Play Again"),
        ),
      ],
    );
  }
}
