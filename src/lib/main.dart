import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sudokme/difficulty_screen.dart';
import 'package:sudokme/sudoku_logic.dart';
import 'package:sudokme/history_manager.dart';
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
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[300]!),
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

  void _saveGameHistory(bool won) {
    final historyItem = GameHistoryItem(
      date: DateTime.now(),
      won: won,
      difficulty: widget.difficulty.toString().split('.').last,
      timeSeconds: _secondsElapsed,
      finalGrid: _sudokuLogic.grid,
      initialGridFlags: _initialGrid,
    );
    HistoryManager().saveGame(historyItem);
  }

  void _showGameOverDialog() {
    _saveGameHistory(false);
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
    _saveGameHistory(true);
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
      _startTimer();
    });
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_capitalize(widget.difficulty.toString().split('.').last)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _getHint,
            color: Colors.blue[600],
            tooltip: 'Hint',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Status Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Errors',
                        style: TextStyle(color: Colors.blue[400], fontSize: 14),
                      ),
                      Text(
                        '${_sudokuLogic.mistakes}/3',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(color: Colors.blue[400], fontSize: 14),
                      ),
                      Text(
                        _formatDuration(_secondsElapsed),
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue[800]!, width: 2.0),
                    ),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                right: BorderSide(
                                  color: Colors.blue[800]!,
                                  width: (col + 1) % 3 == 0 && col != 8
                                      ? 2.0
                                      : 0.5,
                                ),
                                bottom: BorderSide(
                                  color: Colors.blue[800]!,
                                  width: (row + 1) % 3 == 0 && row != 8
                                      ? 2.0
                                      : 0.5,
                                ),
                              ),
                              color: _hintRow == row && _hintCol == col
                                  ? Colors.yellow[100]
                                  : _flashRow == row && _flashCol == col
                                  ? Colors.green[100]
                                  : _selectedRow == row && _selectedCol == col
                                  ? Colors.blue[200]
                                  : (_selectedNumber != null &&
                                        _selectedNumber != 0 &&
                                        _selectedNumber ==
                                            _sudokuLogic.grid[row][col])
                                  ? Colors.blue[50]
                                  : Colors.white,
                            ),
                            child: Center(
                              child: Text(
                                number == 0 ? '' : number.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  color: _initialGrid[row][col]
                                      ? Colors.blue[900]
                                      : Colors.blue[600],
                                  fontWeight: _initialGrid[row][col]
                                      ? FontWeight.w600
                                      : FontWeight.w400,
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
              ),
            ),

            // Number Pad
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final number = index + 1;
                      return _buildNumberButton(number);
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      final number = index + 6;
                      return _buildNumberButton(number);
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

  Widget _buildNumberButton(int number) {
    bool available = _isNumberAvailable(number);
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[50],
          foregroundColor: Colors.blue[800],
          disabledBackgroundColor: Colors.grey[100],
          disabledForegroundColor: Colors.grey[400],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: available ? () => _onNumberSelected(number) : null,
        child: Text(
          number.toString(),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
