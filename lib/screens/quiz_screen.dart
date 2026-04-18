import 'package:flutter/material.dart';
import '../app_config.dart';
import '../models/question.dart';
import '../services/trivia_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ── Core state ──────────────────────────────────
  List<Question> _questions = [];
  List<String> _currentAnswers = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _loading = true;
  bool _answered = false;
  String? _selectedAnswer;
  String? _errorMessage;

  // ── Extension 1: Adaptive Hint Coach (added Phase 6) ──
  // String? _hint;
  // bool _hintVisible = false;

  // ── Extension 2: Difficulty Personalization (added Phase 7) ──
  // int _correctStreak = 0;
  // int _wrongStreak = 0;
  // String _currentDifficulty = 'EASY';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final questions = await TriviaService.fetchQuestions(
        apiKey: AppConfig.quizApiKey,
        limit: 10,
        // Phase 7: replace 'EASY' with _currentDifficulty
        difficulty: 'EASY',
      );
      setState(() {
        _questions = questions;
        _currentIndex = 0;
        _score = 0;
        _prepareQuestion();
        _loading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _loading = false; });
    }
  }

  void _prepareQuestion() {
    if (_questions.isEmpty) return;
    _currentAnswers = _questions[_currentIndex].shuffledAnswers;
    _answered = false;
    _selectedAnswer = null;
    // Phase 6: also reset _hint and _hintVisible here
  }

  void _onAnswerTap(String answer) {
    if (_answered) return;
    final correct = _questions[_currentIndex].correctAnswer;
    final isCorrect = answer == correct;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) _score++;
      // Phase 7: update streaks here
    });
    // Snackbar feedback
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        isCorrect ? '✅ Correct!' : '❌ Wrong! Correct: $correct',
      ),
      backgroundColor:
          isCorrect ? Colors.green.shade700 : Colors.red.shade700,
      duration: const Duration(milliseconds: 1500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
    // NOTE: NO auto-advance here — user must tap Next button
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_currentIndex + 1 >= _questions.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            score: _score,
            total: _questions.length,
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _prepareQuestion();
    });
  }

  Color _buttonColor(String option) {
    if (!_answered) return Colors.white;
    final correct = _questions[_currentIndex].correctAnswer;
    if (option == correct) return Colors.green.shade100;
    if (option == _selectedAnswer) return Colors.red.shade100;
    return Colors.grey.shade100;
  }

  Color _buttonBorder(String option) {
    if (!_answered) return Colors.grey.shade300;
    final correct = _questions[_currentIndex].correctAnswer;
    if (option == correct) return Colors.green.shade400;
    if (option == _selectedAnswer) return Colors.red.shade400;
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
  
  Column(mainAxisSize: MainAxisSize.min, children: [
    Image.asset('assets/images/loading.png', width: 120),
    const SizedBox(height: 16),
    const CircularProgressIndicator(),
    const SizedBox(height: 12),
    const Text('Loading questions...'),
]),
  
          ]),
        ),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Could not load questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Retry'),
              ),
            ]),
          ),
        ),
      );
    }
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} / ${_questions.length}'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Score: $_score',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(children: [
        LinearProgressIndicator(
            value: progress, minHeight: 6, color: Colors.teal.shade600),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category & difficulty chips
                Wrap(spacing: 8, children: [
                  Chip(label: Text(q.category)),
                  Chip(label: Text(q.difficulty.toUpperCase())),
                ]),
                const SizedBox(height: 16),
                // Question text
                Text(q.question,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                // Answer buttons
                ..._currentAnswers.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _buttonColor(opt),
                      border: Border.all(
                          color: _buttonBorder(opt), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _onAnswerTap(opt),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        child: Row(children: [
                          Expanded(
                            child: Text(opt,
                                style: const TextStyle(fontSize: 16))),
                          if (_answered &&
                              opt == _questions[_currentIndex].correctAnswer)
                            const Icon(Icons.check_circle,
                                color: Colors.green),
                          if (_answered &&
                              opt == _selectedAnswer &&
                              opt != _questions[_currentIndex].correctAnswer)
                            const Icon(Icons.cancel, color: Colors.red),
                        ]),
                      ),
                    ),
                  ),
                )),
                // Phase 6: Hint button goes here
                // ── MANUAL NEXT BUTTON ─────────────────────────────
                if (_answered)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentIndex + 1 == _questions.length
                            ? 'See Results →'
                            : 'Next Question →',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
