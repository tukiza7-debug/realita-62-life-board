/// Recovery screen shown when an uncaught error reaches the zone or
/// FlutterError boundary. Lets the user "Start new game" or "Clear saved
/// state" without leaving the app.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key, required this.errors});

  final List<FlutterErrorDetails> errors;

  @override
  Widget build(BuildContext context) {
    final first =
        errors.isNotEmpty ? errors.first.exception.toString() : 'Unknown error';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'Realita +62 hit a problem',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                first,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _clearAndRestart(context),
                child: const Text('Clear saved state and restart'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _showDetails(context),
                child: const Text('Show details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearAndRestart(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {
      // Even clearing failed — there is nothing more we can do here.
    }
    if (context.mounted) {
      // Restart by re-pushing the navigator to the root route.
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in errors) ...[
                  Text(e.exception.toString()),
                  if (e.stack != null)
                    Text(e.stack.toString(),
                        style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 16),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
