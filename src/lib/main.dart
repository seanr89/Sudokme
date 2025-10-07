import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudokme/difficulty_screen.dart';
import 'package:sudokme/sudoku_logic.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sudoku',
      theme: ThemeData(
        primaryColor: Colors.blue[800],
        scaffoldBackgroundColor: Colors.blue[50],
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
      ),
      home: const DifficultyScreen(),
    );
  }
}

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key, required this.difficulty});

  final Difficulty difficulty;

  @override
  SudokuScreenState createState() => SudokuScreenState();
}

class SudokuScreenState extends State<SudokuScreen> {
  final SudokuLogic _sudokuLogic = SudokuLogic();
  int? _selectedNumber;
  int? _selectedRow;
  int? _selectedCol;
  late List<List<bool>> _initialGrid;

  Timer? _timer;
  int _secondsElapsed = 0;
  int? _flashRow;
  int? _flashCol;
  int? _hintRow;
  int? _hintCol;
  int _hintsUsed = 0;

  @override
  void initState() {
    super.initState();
    _sudokuLogic.generateSudoku(widget.difficulty);
    _initialGrid = List.generate(
      9,
      (row) => List.generate(9, (col) => _sudokuLogic.grid[row][col] != 0),
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  bool _isNumberAvailable(int number) {
    int count = 0;
    for (var row in _sudokuLogic.grid) {
      for (var cell in row) {
        if (cell == number) {
          count++;
        }
      }
    }
    return count < 9;
  }

  void _onNumberSelected(int number) {
    if (_selectedRow != null && _selectedCol != null) {
      if (_initialGrid[_selectedRow!][_selectedCol!]) {
        return;
      }
      setState(() {
        if (_sudokuLogic.validateMove(_selectedRow!, _selectedCol!, number)) {
          _sudokuLogic.grid[_selectedRow!][_selectedCol!] = number;
          _selectedNumber = number;
          if (_sudokuLogic.isSolved()) {
            _timer?.cancel();
            _showWinDialog();
          }
          _flashRow = _selectedRow;
          _flashCol = _selectedCol;
          Timer(const Duration(seconds: 1), () {
            setState(() {
              _flashRow = null;
              _flashCol = null;
            });
          });
        } else {
          _sudokuLogic.mistakes++;
          _showIncorrectDialog();
          if (_sudokuLogic.mistakes >= 3) {
            _timer?.cancel();
            _showGameOverDialog();
          }
        }
      });
    }
  }

  void _showIncorrectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incorrect!'),
        content: const Text('That is not the correct number.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text('You have made 3 mistakes.'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _sudokuLogic.generateSudoku(widget.difficulty);
                _sudokuLogic.mistakes = 0;
                _initialGrid = List.generate(
                  9,
                  (row) => List.generate(
                    9,
                    (col) => _sudokuLogic.grid[row][col] != 0,
                  ),
                );
                _startTimer();
              });
              Navigator.of(context).pop();
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  void _getHint() {
    final emptyCells = <List<int>>[];
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_sudokuLogic.grid[i][j] == 0) {
          emptyCells.add([i, j]);
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(emptyCells.length);
      final randomCell = emptyCells[randomIndex];
      final row = randomCell[0];
      final col = randomCell[1];
      final solution = _sudokuLogic.getSolution();
      final number = solution[row][col];

      setState(() {
        _sudokuLogic.grid[row][col] = number;
        _hintRow = row;
        _hintCol = col;
        _hintsUsed++;
      });

      Timer(const Duration(seconds: 1), () {
        setState(() {
          _hintRow = null;
          _hintCol = null;
        });
      });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have solved the puzzle.'),
            Text('Time: ${_formatDuration(_secondsElapsed)}'),
            Text('Errors: ${_sudokuLogic.mistakes}'),
            Text('Hints Used: $_hintsUsed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const DifficultyScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        actions: [
          TextButton(
            onPressed: _getHint,
            child: const Text('Hint'),
          ),
          Center(
            child: Text(
              'Errors: ${_sudokuLogic.mistakes}/3',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Time: ${_formatDuration(_secondsElapsed)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            AspectRatio(
              aspectRatio: 1.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ 9;
                    final col = index % 9;
                    final number = _sudokuLogic.grid[row][col];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRow = row;
                          _selectedCol = col;
                          _selectedNumber = _sudokuLogic.grid[row][col];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: (row == 0) ? 2.0 : 1.0),
                            left: BorderSide(width: (col == 0) ? 2.0 : 1.0),
                            right: BorderSide(
                              width: (col + 1) % 3 == 0 ? 2.0 : 1.0,
                            ),
                            bottom: BorderSide(
                              width: (row + 1) % 3 == 0 ? 2.0 : 1.0,
                            ),
                          ),
                          color: _hintRow == row && _hintCol == col
                              ? Colors.yellow
                              : _flashRow == row && _flashCol == col
                              ? Colors.green
                              : _selectedRow == row && _selectedCol == col
                              ? Colors.blue.withAlpha(128)
                              : (_selectedNumber != null &&
                                    _selectedNumber != 0 &&
                                    _selectedNumber ==
                                        _sudokuLogic.grid[row][col])
                              ? Colors.blue.withAlpha(64)
                              : Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            number == 0
                                ? ''
                                : number.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: _initialGrid[row][col]
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: 81,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final number = index + 1;
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          onPressed: _isNumberAvailable(number)
                              ? () => _onNumberSelected(number)
                              : null,
                          child: Text(number.toString()),
                        ),
                      );
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      final number = index + 6;
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          onPressed: _isNumberAvailable(number)
                              ? () => _onNumberSelected(number)
                              : null,
                          child: Text(number.toString()),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
