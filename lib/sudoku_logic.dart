import 'dart:math';

import 'package:sudokme/difficulty_screen.dart';

class SudokuLogic {
  List<List<int>> grid = List.generate(9, (_) => List.generate(9, (_) => 0));
  late List<List<int>> solutionGrid;
  int mistakes = 0;

  void generateSudoku(Difficulty difficulty) {
    grid = List.generate(9, (_) => List.generate(9, (_) => 0));
    _fillGrid(grid);
    solutionGrid = List.generate(9, (i) => List.from(grid[i]));
    _removeNumbers(difficulty);
  }

  bool _fillGrid(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (int number in numbers) {
            if (_isValid(grid, row, col, number)) {
              grid[row][col] = number;
              if (_fillGrid(grid)) {
                return true;
              } else {
                grid[row][col] = 0;
              }
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  void _removeNumbers(Difficulty difficulty) {
    int numbersToRemove = 0;
    switch (difficulty) {
      case Difficulty.easy:
        numbersToRemove = 40;
        break;
      case Difficulty.medium:
        numbersToRemove = 50;
        break;
      case Difficulty.hard:
        numbersToRemove = 60;
        break;
    }

    Random random = Random();
    while (numbersToRemove > 0) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);
      if (grid[row][col] != 0) {
        int temp = grid[row][col];
        grid[row][col] = 0;
        if (_countSolutions(List.generate(9, (i) => List.from(grid[i]))) != 1) {
          grid[row][col] = temp;
        } else {
          numbersToRemove--;
        }
      }
    }
  }

  int _countSolutions(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          int count = 0;
          for (int number = 1; number <= 9; number++) {
            if (_isValid(grid, row, col, number)) {
              grid[row][col] = number;
              count += _countSolutions(grid);
              grid[row][col] = 0;
            }
          }
          return count;
        }
      }
    }
    return 1;
  }

  bool _isValid(List<List<int>> grid, int row, int col, int number) {
    // Check row
    for (int i = 0; i < 9; i++) {
      if (grid[row][i] == number) {
        return false;
      }
    }

    // Check column
    for (int i = 0; i < 9; i++) {
      if (grid[i][col] == number) {
        return false;
      }
    }

    // Check 3x3 box
    int boxRow = row - row % 3;
    int boxCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[boxRow + i][boxCol + j] == number) {
          return false;
        }
      }
    }

    return true;
  }

  bool validateMove(int row, int col, int number) {
    return solutionGrid[row][col] == number;
  }

  bool isSolved() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          return false;
        }
      }
    }
    return true;
  }

  List<List<int>> getSolution() {
    return solutionGrid;
  }
}
