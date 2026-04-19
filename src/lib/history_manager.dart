import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameHistoryItem {
  final DateTime date;
  final bool won;
  final String difficulty;
  final int timeSeconds;
  final List<List<int>> finalGrid;
  final List<List<bool>> initialGridFlags;

  GameHistoryItem({
    required this.date,
    required this.won,
    required this.difficulty,
    required this.timeSeconds,
    required this.finalGrid,
    required this.initialGridFlags,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'won': won,
      'difficulty': difficulty,
      'timeSeconds': timeSeconds,
      'finalGrid': finalGrid,
      'initialGridFlags': initialGridFlags,
    };
  }

  factory GameHistoryItem.fromJson(Map<String, dynamic> json) {
    return GameHistoryItem(
      date: DateTime.parse(json['date']),
      won: json['won'],
      difficulty: json['difficulty'],
      timeSeconds: json['timeSeconds'],
      finalGrid: List<List<int>>.from(
        json['finalGrid'].map((x) => List<int>.from(x)),
      ),
      initialGridFlags: List<List<bool>>.from(
        json['initialGridFlags'].map((x) => List<bool>.from(x)),
      ),
    );
  }
}

class HistoryManager {
  static const String _historyKey = 'sudoku_game_history';

  Future<void> saveGame(GameHistoryItem game) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = await getHistory();
    historyList.insert(0, game); // Add to the beginning

    final String encodedData = jsonEncode(
      historyList.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_historyKey, encodedData);
  }

  Future<List<GameHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_historyKey);

    if (historyString == null) {
      return [];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(historyString);
      return decodedData
          .map((item) => GameHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
