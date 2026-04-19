import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudokme/auth_service.dart';
import 'package:sudokme/history_screen.dart';
import 'package:sudokme/main.dart';

enum Difficulty { easy, medium, hard }

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Difficulty')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'Anonymous'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.email?[0].toUpperCase() ?? 'A',
                  style: const TextStyle(fontSize: 40.0),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Game History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                AuthService().signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose your level',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 40),
              _buildDifficultyCard(
                context,
                'Easy',
                'A gentle start',
                Difficulty.easy,
                Icons.sentiment_satisfied_alt,
              ),
              const SizedBox(height: 20),
              _buildDifficultyCard(
                context,
                'Medium',
                'A moderate challenge',
                Difficulty.medium,
                Icons.sentiment_neutral,
              ),
              const SizedBox(height: 20),
              _buildDifficultyCard(
                context,
                'Hard',
                'For advanced players',
                Difficulty.hard,
                Icons.sentiment_very_dissatisfied,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context,
    String title,
    String subtitle,
    Difficulty difficulty,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue[100]!, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SudokuScreen(difficulty: difficulty),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.blue[400]),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 16, color: Colors.blue[400]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
            ],
          ),
        ),
      ),
    );
  }
}
