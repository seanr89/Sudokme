import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Stream<QuerySnapshot>? _gamesStream;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'game-store',
      );
      _gamesStream = firestore
          .collection('games')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots();
    } else {
      // Handle the case where user is null
      _gamesStream = Stream.empty();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    }
    return 'No date';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _gamesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Error loading game history: ${snapshot.error}');
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No games played yet.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    '${data['difficulty']} - ${data['won'] ? 'Won' : 'Lost'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time: ${_formatDuration(data['timeElapsed'])}'),
                      Text('Mistakes: ${data['mistakes']}'),
                      Text('Hints: ${data['hintsUsed']}'),
                    ],
                  ),
                  trailing: Text(_formatTimestamp(data['timestamp'])),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
