import 'package:flutter/material.dart';
import 'quiz_screen.dart';
 
class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
 
  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
  });
 
  String get _message {
    final pct = score / total;
    if (pct == 1.0) return 'Perfect Score! 🏆';
    if (pct >= 0.8) return 'Excellent! 🎉';
    if (pct >= 0.6) return 'Good Job! 👍';
    if (pct >= 0.4) return 'Keep Practicing! 💪';
    return 'Better Luck Next Time! 🎯';
  }
 
  bool get _isCelebration => score / total >= 0.8;
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration image shown when score is 80% or above
              if (_isCelebration)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image.asset(
                    'assets/images/celebrate.jpg',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
 
              // Quiz complete heading
              Text(
                'Quiz Complete!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
 
              // Score circle
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.shade50,
                  border: Border.all(
                    color: Colors.teal.shade400,
                    width: 4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score / $total',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Score',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
 
              // Result message
              Text(
                _message,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
 
              // Hint reminder if score was low
              if (!_isCelebration)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '💡 Remember: use the hint button after a wrong\nanswer to get a second attempt next time!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
 
              const SizedBox(height: 28),
 
              // Play again button
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuizScreen(),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Play Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}