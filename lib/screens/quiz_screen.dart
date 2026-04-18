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
  // ── Core state ─────────────────────────────────────────────────────────────
  List<Question> _questions = [];
  List<String> _currentAnswers = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _loading = true;
  bool _answered = false; // true = fully locked (no more taps)
  String? _selectedAnswer; // the final selected answer (2nd attempt or correct 1st)
  String? _errorMessage;
 
  // ── Extension 1: Adaptive Hint Coach (2-attempt system) ───────────────────
  int _attemptsUsed = 0;         // 0 = not tried, 1 = one wrong attempt made
  String? _firstWrongAnswer;     // stores the first wrong pick for red highlight
  bool _showHintButton = false;  // whether the hint button is visible
  bool _hintVisible = false;     // whether hint text is expanded
  String? _hint;                 // generated hint text
 
  // ── Extension 2: Difficulty Personalization Engine ─────────────────────────
  int _correctStreak = 0;
  int _wrongStreak = 0;
  String _currentDifficulty = 'EASY';
 
  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }
 
  // ── Data loading ───────────────────────────────────────────────────────────
 
  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final questions = await TriviaService.fetchQuestions(
        apiKey: AppConfig.quizApiKey,
        limit: 10,
        difficulty: _currentDifficulty,
      );
      setState(() {
        _questions = questions;
        _currentIndex = 0;
        _score = 0;
        _prepareQuestion();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }
 
  // ── Question preparation ───────────────────────────────────────────────────
 
  void _prepareQuestion() {
    if (_questions.isEmpty) return;
    _currentAnswers = _questions[_currentIndex].shuffledAnswers;
    _answered = false;
    _selectedAnswer = null;
    // Reset 2-attempt state
    _attemptsUsed = 0;
    _firstWrongAnswer = null;
    _showHintButton = false;
    _hintVisible = false;
    _hint = null;
  }
 
  // ── Answer tap handler (2-attempt logic) ───────────────────────────────────
 
  void _onAnswerTap(String answer) {
    if (_answered) return; // fully locked — ignore all taps
 
    final correct = _questions[_currentIndex].correctAnswer;
    final isCorrect = answer == correct;
 
    if (_attemptsUsed == 0) {
      // ── FIRST ATTEMPT ──────────────────────────────────────────────────────
      if (isCorrect) {
        // Correct on first try — full score, lock immediately
        setState(() {
          _selectedAnswer = answer;
          _answered = true;
          _score++;
          _correctStreak++;
          _wrongStreak = 0;
          _adjustDifficulty();
        });
        _showFeedbackSnackBar(true, correct, firstAttempt: true);
      } else {
        // Wrong on first try — show hint, allow one more attempt
        setState(() {
          _firstWrongAnswer = answer;
          _attemptsUsed = 1;
          _showHintButton = true;
          _hint = _generateHint(_questions[_currentIndex]);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              const Text('❌ Not quite! Use the hint and try once more.'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } else {
      // ── SECOND ATTEMPT — lock regardless of result ─────────────────────────
      setState(() {
        _selectedAnswer = answer;
        _answered = true;
        // No score awarded on second attempt
        _wrongStreak++;
        _correctStreak = 0;
        _adjustDifficulty();
      });
      _showFeedbackSnackBar(isCorrect, correct, firstAttempt: false);
    }
  }
 
  // ── Snackbar helper ────────────────────────────────────────────────────────
 
  void _showFeedbackSnackBar(bool isCorrect, String correct,
      {required bool firstAttempt}) {
    String message;
    Color color;
    if (isCorrect && firstAttempt) {
      message = '✅ Correct!';
      color = Colors.green.shade700;
    } else if (isCorrect && !firstAttempt) {
      message = '✅ Correct on second try! (No points — use hints wisely)';
      color = Colors.teal.shade700;
    } else {
      message = '❌ Wrong! The correct answer was: $correct';
      color = Colors.red.shade700;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(milliseconds: 2000),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
 
  // ── Next question / navigate to results ───────────────────────────────────
 
  void _nextQuestion() {
    if (!mounted) return;
    if (_currentIndex + 1 >= _questions.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(score: _score, total: _questions.length),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _prepareQuestion();
    });
  }
 
  // ── Hint generator (Extension 1) ──────────────────────────────────────────
 
  String _generateHint(Question q) {
    final correct = q.correctAnswer;
    final firstLetter =
        correct.isNotEmpty ? correct[0].toUpperCase() : '?';
    final wordCount = correct.trim().split(RegExp(r'\s+')).length;
 
    final categoryHints = {
      'Programming': 'Think about syntax, keywords, or runtime behavior.',
      'DevOps': 'Think about tools, pipelines, or deployment steps.',
      'Linux': 'Think about terminal commands or file system structure.',
      'Docker': 'Think about containers, images, or compose files.',
      'SQL': 'Think about query structure or database operations.',
      'Code': 'Think about language rules or compiler behavior.',
      'Web': 'Think about HTTP, HTML, CSS, or browser APIs.',
    };
 
    final categoryHint =
        categoryHints[q.category] ?? 'Think carefully about the topic.';
 
    return '💡 The answer starts with "$firstLetter" '
        'and is $wordCount word(s) long.\n\n$categoryHint';
  }
 
  // ── Difficulty adjustment (Extension 2) ───────────────────────────────────
 
  void _adjustDifficulty() {
    if (_correctStreak >= 3) {
      if (_currentDifficulty == 'EASY') _currentDifficulty = 'MEDIUM';
      else if (_currentDifficulty == 'MEDIUM') _currentDifficulty = 'HARD';
      _correctStreak = 0;
    } else if (_wrongStreak >= 2) {
      if (_currentDifficulty == 'HARD') _currentDifficulty = 'MEDIUM';
      else if (_currentDifficulty == 'MEDIUM') _currentDifficulty = 'EASY';
      _wrongStreak = 0;
    }
  }
 
  // ── Button color logic ─────────────────────────────────────────────────────
 
  Color _buttonColor(String option) {
    final correct = _questions[_currentIndex].correctAnswer;
 
    if (_answered) {
      // Final locked state
      if (option == correct) return Colors.green.shade100;
      if (option == _selectedAnswer) return Colors.red.shade100;
      if (option == _firstWrongAnswer) return Colors.red.shade50;
      return Colors.grey.shade100;
    }
 
    if (_attemptsUsed == 1) {
      // After first wrong — highlight that pick, others remain tappable
      if (option == _firstWrongAnswer) return Colors.red.shade100;
      return Colors.white;
    }
 
    return Colors.white;
  }
 
  Color _buttonBorder(String option) {
    final correct = _questions[_currentIndex].correctAnswer;
 
    if (_answered) {
      if (option == correct) return Colors.green.shade400;
      if (option == _selectedAnswer) return Colors.red.shade400;
      if (option == _firstWrongAnswer) return Colors.red.shade200;
      return Colors.grey.shade300;
    }
 
    if (_attemptsUsed == 1 && option == _firstWrongAnswer) {
      return Colors.red.shade300;
    }
 
    return Colors.grey.shade300;
  }
 
  // Whether this button should accept taps
  bool _buttonEnabled(String option) {
    if (_answered) return false;                  // fully locked
    if (_attemptsUsed == 1 && option == _firstWrongAnswer) return false; // can't repick same wrong answer
    return true;
  }
 
  // Answer icon shown after final lock
  Widget? _answerIcon(String option) {
    if (!_answered) return null;
    final correct = _questions[_currentIndex].correctAnswer;
    if (option == correct) {
      return Image.asset('assets/icons/correct.png', width: 24, height: 24);
    }
    if (option == _selectedAnswer && option != correct) {
      return Image.asset('assets/icons/wrong.jpg', width: 24, height: 24);
    }
    return null;
  }
 
  // ── BUILD ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/loading.png', width: 130),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              const Text(
                'Loading questions...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
 
    // Error state
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Could not load questions',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadQuestions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
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
          // Difficulty chip (Extension 2)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Chip(
              label: Text(
                _currentDifficulty,
                style:
                    const TextStyle(fontSize: 11, color: Colors.white),
              ),
              backgroundColor: _currentDifficulty == 'HARD'
                  ? Colors.red.shade700
                  : _currentDifficulty == 'MEDIUM'
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
              padding: EdgeInsets.zero,
            ),
          ),
          // Score
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: Colors.teal.shade600,
            backgroundColor: Colors.teal.shade100,
          ),
 
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
                    // Attempt indicator
                    if (_attemptsUsed == 1 && !_answered)
                      Chip(
                        label: const Text(
                          '1 attempt used — try again',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: Colors.orange.shade600,
                      ),
                  ]),
                  const SizedBox(height: 16),
 
                  // Question text
                  Text(
                    q.question,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
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
                            onTap: _buttonEnabled(opt)
                                ? () => _onAnswerTap(opt)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      opt,
                                      style:
                                          const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  if (_answerIcon(opt) != null)
                                    _answerIcon(opt)!,
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),
 
                  // ── Hint section (Extension 1) ─────────────────────────
                  if (_showHintButton && !_answered) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _hintVisible = !_hintVisible);
                      },
                      icon: Icon(
                        _hintVisible
                            ? Icons.lightbulb
                            : Icons.lightbulb_outline,
                        color: Colors.amber.shade700,
                      ),
                      label: Text(
                        _hintVisible ? 'Hide Hint' : 'Get Hint',
                        style:
                            TextStyle(color: Colors.amber.shade700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.amber.shade600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (_hintVisible && _hint != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.amber.shade300),
                        ),
                        child: Text(
                          _hint!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
 
                  // ── Manual Next button (appears only after fully answered) ──
                  if (_answered)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
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
        ],
      ),
    );
  }
}
