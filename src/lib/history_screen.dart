import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sudokme/history_manager.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryManager _historyManager = HistoryManager();
  late Future<List<GameHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyManager.getHistory();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Widget _buildMiniGrid(
      List<List<int>> grid, List<List<bool>> initialGridFlags) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.white,
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 81,
        itemBuilder: (context, index) {
          final row = index ~/ 9;
          final col = index % 9;
          final number = grid[row][col];
          final isInitial = initialGridFlags[row][col];

          return Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(width: (row == 0) ? 0.0 : 1.0, color: Colors.black54),
                left: BorderSide(width: (col == 0) ? 0.0 : 1.0, color: Colors.black54),
                right: BorderSide(
                    width: (col + 1) % 3 == 0 ? 2.0 : 1.0, color: Colors.black),
                bottom: BorderSide(
                    width: (row + 1) % 3 == 0 ? 2.0 : 1.0, color: Colors.black),
              ),
            ),
            child: Center(
              child: Text(
                number == 0 ? '' : number.toString(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isInitial ? FontWeight.bold : FontWeight.normal,
                  color: isInitial ? Colors.black : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku Game History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<GameHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading history'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No game history yet.'));
          }

          final history = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy').format(item.date),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  item.won ? Icons.check_circle : Icons.cancel,
                                  color: item.won ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.won ? 'Won' : 'Lost',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Difficulty: ${item.difficulty}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Time: ${_formatDuration(item.timeSeconds)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      _buildMiniGrid(item.finalGrid, item.initialGridFlags),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
