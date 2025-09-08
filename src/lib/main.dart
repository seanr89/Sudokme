import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudokme/difficulty_screen.dart';
import 'package:sudokme/sudoku_logic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  bool _showSolution = false;

  @override
  void initState() {
    super.initState();
    _sudokuLogic.generateSudoku(widget.difficulty);
    _initialGrid = List.generate(
      9,
      (row) => List.generate(9, (col) => _sudokuLogic.grid[row][col] != 0),
    );
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
            _showWinDialog();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Correct!'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          _sudokuLogic.mistakes++;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect!'),
              duration: Duration(seconds: 1),
            ),
          );
          if (_sudokuLogic.mistakes >= 3) {
            _showGameOverDialog();
          }
        }
      });
    }
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
              });
              Navigator.of(context).pop();
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You Win!'),
        content: const Text('Congratulations, you have solved the puzzle!'),
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
              });
              Navigator.of(context).pop();
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
        title: const Text('Sudoku'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showSolution = true;
                });
              },
              child: const Text('Solve', style: TextStyle(color: Colors.black)),
            ),
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
            Expanded(
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
                          color: _showSolution && !_initialGrid[row][col]
                              ? Colors.yellow
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
                            _showSolution
                                ? _sudokuLogic
                                      .getSolution()[row][col]
                                      .toString()
                                : number == 0
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
                          onPressed: () => _onNumberSelected(number),
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
                          onPressed: () => _onNumberSelected(number),
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
