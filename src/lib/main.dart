import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sudokme/difficulty_screen.dart';
import 'package:sudokme/sudoku_logic.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'auth_service.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    StreamProvider<User?>.value(
      value: AuthService().user,
      initialData: null,
      child: const MyApp(),
    ),
  );
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const LoginScreen();
    } else {
      return const DifficultyScreen();
    }
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
  late List<List<int>> _initialPuzzle;

  @override
  void initState() {
    super.initState();
    _sudokuLogic.generateSudoku(widget.difficulty);
    _initialGrid = List.generate(
      9,
      (row) => List.generate(9, (col) => _sudokuLogic.grid[row][col] != 0),
    );
    _initialPuzzle = List.generate(
      9,
      (row) => List.from(_sudokuLogic.grid[row]),
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
          if (_sudokuLogic.mistakes >= 3) {
            _timer?.cancel();
            _showGameOverDialog();
          } else {
            _showIncorrectDialog();
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

  Future<void> _saveGameToFirestore(bool won) async {
    await _sudokuLogic.saveGame(
      won: won,
      timeElapsed: _secondsElapsed,
      mistakes: _sudokuLogic.mistakes,
      hintsUsed: _hintsUsed,
      difficulty: widget.difficulty,
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text(
          'You have made 3 mistakes. Would you like to save your game?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _saveGameToFirestore(false);
              if (!mounted) return;
              navigator.pop();
              _startNewGame();
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text('No'),
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
            const Text(
              'You have solved the puzzle. Would you like to save your game?',
            ),
            Text('Time: ${_formatDuration(_secondsElapsed)}'),
            Text('Errors: ${_sudokuLogic.mistakes}'),
            Text('Hints Used: $_hintsUsed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _saveGameToFirestore(true);
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const DifficultyScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const DifficultyScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  void _startNewGame() {
    setState(() {
      _sudokuLogic.generateSudoku(widget.difficulty);
      _sudokuLogic.mistakes = 0;
      _initialGrid = List.generate(
        9,
        (row) => List.generate(9, (col) => _sudokuLogic.grid[row][col] != 0),
      );
      _initialPuzzle = List.generate(
        9,
        (row) => List.from(_sudokuLogic.grid[row]),
      );
      _startTimer();
    });
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mode - ${_capitalize(widget.difficulty.toString().split('.').last)}',
        ),
        actions: [
          ElevatedButton(onPressed: _getHint, child: const Text('Hint')),
          const SizedBox(width: 10),
          Center(
            child: Text(
              'Errors: ${_sudokuLogic.mistakes}/3',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
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
            // grid display should go here
            AspectRatio(
              aspectRatio: 1.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
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
                            number == 0 ? '' : number.toString(),
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
                    children: List.generate(3, (index) {
                      final number = index + 1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            onPressed: _isNumberAvailable(number)
                                ? () => _onNumberSelected(number)
                                : null,
                            child: Text(number.toString()),
                          ),
                        ),
                      );
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      final number = index + 4;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            onPressed: _isNumberAvailable(number)
                                ? () => _onNumberSelected(number)
                                : null,
                            child: Text(number.toString()),
                          ),
                        ),
                      );
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      final number = index + 7;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            onPressed: _isNumberAvailable(number)
                                ? () => _onNumberSelected(number)
                                : null,
                            child: Text(number.toString()),
                          ),
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
