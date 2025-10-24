# Sudokme

A simple and clean Sudoku application built with Flutter.

## Features

*   **Multiple Difficulty Levels:** Choose from Easy, Medium, and Hard difficulties.
*   **Mistake Tracking:** The game tracks the number of mistakes you make.
*   **Timer:** See how long it takes you to solve the puzzle.
*   **Hints:** Get a hint if you're stuck.
*   **Win/Game Over Dialogs:** Get notified when you win or lose the game.

## Application Logic

The core logic of the application is divided into three main parts:

### 1. Difficulty Selection (`difficulty_screen.dart`)

*   The application starts with the `DifficultyScreen`, where the user can select their desired difficulty level (Easy, Medium, or Hard).
*   Based on the selection, the application navigates to the `SudokuScreen`, passing the chosen difficulty as a parameter.

### 2. Game Screen (`main.dart`)

*   The `SudokuScreen` is the main screen where the Sudoku game is played.
*   It receives the difficulty level from the `DifficultyScreen` and uses it to generate a new Sudoku puzzle.
*   The `SudokuScreenState` class manages the state of the game, including:
    *   The Sudoku grid.
    *   A timer to track the duration of the game.
    *   The number of mistakes made by the user.
    *   The number of hints used.
*   The UI is built with a `GridView` to represent the Sudoku board and a set of `ElevatedButton`s for number input.
*   User interactions, such as tapping on a cell or selecting a number, are handled to update the game state.
*   The application provides feedback to the user through dialogs for incorrect moves, winning the game, and game over (after 3 mistakes).

### 3. Sudoku Logic (`sudoku_logic.dart`)

*   The `SudokuLogic` class encapsulates the core logic for generating and solving Sudoku puzzles.
*   **Puzzle Generation:**
    1.  A complete, valid Sudoku grid is generated using a backtracking algorithm (`_fillGrid`).
    2.  Numbers are then removed from the grid based on the selected difficulty (`_removeNumbers`). The number of removed digits determines the puzzle's difficulty.
    3.  Crucially, the puzzle generation ensures that there is always a single, unique solution. This is verified by the `_countSolutions` method.
*   **Move Validation:**
    *   When the user makes a move, the `validateMove` method checks if the entered number is correct by comparing it to the original, solved grid.
*   **Game State:**
    *   The class also includes methods to check if the puzzle is solved (`isSolved`) and to get the solution (`getSolution`) for providing hints.

## File Structure

*   `lib/main.dart`: Contains the main application entry point and the `SudokuScreen` widget where the game is played.
*   `lib/difficulty_screen.dart`: The initial screen for selecting the game difficulty.
*   `lib/sudoku_logic.dart`: The core logic for generating and managing the Sudoku puzzles.
*   `pubspec.yaml`: Lists the project dependencies, such as `flutter` and `google_fonts`.