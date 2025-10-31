import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
// compile-time flag to auto-demo the Results screen when set via
// `--dart-define=AUTO_DEMO=true` during build/run. Useful for automated screenshots.
const bool kAutoDemo = bool.fromEnvironment('AUTO_DEMO', defaultValue: false);
// lightweight html entity unescape helper (covers common entities from OpenTDB)

String unescapeHtml(String input) {
  if (input.isEmpty) return input;
  var s = input;
  const entities = {
    '&quot;': '"',
    '&#039;': "'",
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&uuml;': 'ü',
    '&eacute;': 'é',
    '&rsquo;': "'",
    '&ldquo;': '"',
    '&rdquo;': '"',
    '&ndash;': '-',
  };
  entities.forEach((k, v) {
    s = s.replaceAll(k, v);
  });
  // decode numeric entities like &#39;
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1) ?? '0') ?? 0;
    return String.fromCharCode(code);
  });
  return s;
}
void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quizzical',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3F51B5), // Indigo
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF303F9F), foregroundColor: Colors.white, elevation: 0),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF303F9F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
      ),
      home: const HomeScreen(),
    );
  }
}
class ApiService {
  final _base = 'https://opentdb.com';

  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse('$_base/api_category.php');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load categories');
    final data = json.decode(res.body);
    final cats = (data['trivia_categories'] as List)
        .map((e) => Category.fromJson(e))
        .toList();
    return cats;
  }

  Future<List<Question>> fetchQuestions({
    required int amount,
    required int categoryId,
    String? difficulty, // 'easy','medium','hard' or null
  }) async {
    final params = {
      'amount': amount.toString(),
      'category': categoryId.toString(),
      'type': 'multiple',
    };
    if (difficulty != null && difficulty != 'any') params['difficulty'] = difficulty;
    final uri = Uri.parse('$_base/api.php').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load questions');
    final data = json.decode(res.body);
  final results = (data['results'] as List)
    .map((e) => Question.fromJson(e))
    .toList();
    return results;
  }
}

class Category {
  final int id;
  final String name;
  Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) => Category(id: j['id'], name: j['name']);
}

class Question {
  final String question;
  final String correct;
  final List<String> incorrect;
  Question({required this.question, required this.correct, required this.incorrect});
  List<String> allAnswers() {
    final list = List<String>.from(incorrect);
    list.add(correct);
    list.shuffle();
    return list;
  }

  factory Question.fromJson(Map<String, dynamic> j) {
    String q = unescapeHtml(j['question'] as String);
    String correct = unescapeHtml(j['correct_answer'] as String);
    final inc = (j['incorrect_answers'] as List).map((e) => unescapeHtml(e as String)).toList();
    return Question(question: q, correct: correct, incorrect: inc);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // If AUTO_DEMO is enabled at compile/run time, navigate to the Results screen
    // automatically to make capturing screenshots deterministic.
    if (kAutoDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // small delay so the app can render the home UI briefly before navigating
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultsScreen(score: 8, total: 10, category: Category(id: 0, name: 'Demo'), amount: 10)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Hero illustration (placeholder icon)
              Container(
                height: 320,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.quiz_rounded, size: 96, color: Color(0xFF303F9F)),
                    const SizedBox(height: 12),
                    const Text('Quizzical', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Rayhan 21cse050', style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('GET STARTED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _api = ApiService();
  late Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final cats = snapshot.data ?? [];
          return ListView.separated(
            itemCount: cats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = cats[index];
              return ListTile(
                title: Text(c.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConfigScreen(category: c))),
              );
            },
          );
        },
      ),
    );
  }
}

class ConfigScreen extends StatefulWidget {
  final Category category;
  const ConfigScreen({super.key, required this.category});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  int _amount = 10;
  String _difficulty = 'any';
  final _api = ApiService();
  bool _loading = false;

  void _startQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final qs = await _api.fetchQuestions(amount: _amount, categoryId: widget.category.id, difficulty: _difficulty == 'any' ? null : _difficulty);
      if (!mounted) return;
      if (qs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No questions found for this configuration')));
        setState(() => _loading = false);
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuizScreen(questions: qs, category: widget.category, amount: _amount, difficulty: _difficulty == 'any' ? null : _difficulty)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Start Quiz - ${widget.category.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${widget.category.name}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '10',
                decoration: const InputDecoration(labelText: 'Number of questions', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0 || n > 50) return 'Enter 1-50';
                  return null;
                },
                onSaved: (v) => _amount = int.tryParse(v ?? '10') ?? 10,
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null) _amount = n;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _difficulty,
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any')),
                  DropdownMenuItem(value: 'easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'hard', child: Text('Hard')),
                ],
                onChanged: (v) => setState(() => _difficulty = v ?? 'any'),
                decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _startQuiz,
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
                  child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Start Quiz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final Category category;
  final int amount;
  final String? difficulty;
  const QuizScreen({super.key, required this.questions, required this.category, required this.amount, this.difficulty});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _score = 0;
  String? _selected;
  late List<String> _options;
  bool _answered = false; // whether the user has answered current question
  bool _lastAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _options = widget.questions[_index].allAnswers();
  }

  void _select(String answer) {
    // ignore taps if already answered
    if (_answered) return;
    final q = widget.questions[_index];
    final correct = answer == q.correct;
    setState(() {
      _selected = answer;
      _answered = true;
      _lastAnswerCorrect = correct;
      if (correct) _score++;
    });
    // ensure the color renders, then wait briefly and auto-advance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _next();
      });
    });
  }

  void _next() {
    // only proceed after an answer was given
    if (!_answered) return;
    if (_index + 1 >= widget.questions.length) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultsScreen(score: _score, total: widget.questions.length, category: widget.category, amount: widget.amount, difficulty: widget.difficulty)));
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
      _lastAnswerCorrect = false;
      _options = widget.questions[_index].allAnswers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_index];
    final progress = (_index + 1) / widget.questions.length;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: progress, minHeight: 6),
            const SizedBox(height: 12),
            Text('Question ${_index + 1} of ${widget.questions.length}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(q.question, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 12),
            ..._options.map((opt) {
              // Only change color for the tapped button after answering.
              Color? bg;
              Color? fg;
              if (_answered && opt == _selected) {
                // selected button: green if correct, light red if incorrect
                if (_lastAnswerCorrect) {
                  bg = Colors.green[600];
                  fg = Colors.white;
                } else {
                  bg = Colors.red[300];
                  fg = Colors.white;
                }
              } else {
                // default button appearance: use theme's onPrimary so text contrasts with indigo
                bg = null;
                fg = Theme.of(context).colorScheme.onPrimary;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: fg,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // keep button appearance enabled for all options; ignore taps after answered
                    if (_answered) return;
                    _select(opt);
                  },
                  child: Align(alignment: Alignment.centerLeft, child: Text(opt, style: TextStyle(color: fg))),
                ),
              );
            }),
            const Spacer(),
            // Auto-advance after answer; no Next button required per UX
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  final int score;
  final int total;
  final Category category;
  final int amount;
  final String? difficulty;
  const ResultsScreen({super.key, required this.score, required this.total, required this.category, required this.amount, this.difficulty});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = false;
  late final AnimationController _animController;
  late final Animation<double> _pulse;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = Tween<double>(begin: 0.9, end: 1.12).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    _animController.addStatusListener((s) {
      if (s == AnimationStatus.completed) _animController.reverse();
      else if (s == AnimationStatus.dismissed) _animController.forward();
    });
    _animController.forward();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // auto-play confetti for high scores
    final pct = widget.total > 0 ? widget.score / widget.total : 0.0;
    if (pct > 0.7) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Widget _buildPerformanceWidget(double pct) {
    if (pct > 0.7) {
      return Column(
        children: [
          ScaleTransition(
            scale: _pulse,
            child: const Icon(Icons.emoji_events, size: 86, color: Colors.amber),
          ),
          const SizedBox(height: 12),
          const Text('Excellent!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 6),
          const Text('Great job — you scored above 70%'),
        ],
      );
    } else if (pct >= 0.4) {
      // Medium: show a Lottie animation (thumbs-up / encouraging)
      return Column(
        children: [
          ScaleTransition(
            scale: _pulse,
              child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/lottie/medium.json',
                fit: BoxFit.contain,
                repeat: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Good effort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 6),
          const Text('You did well — keep it up!'),
        ],
      );
    } else {
      // Poor: show a gentle Lottie encouragement animation
      return Column(
        children: [
          ScaleTransition(
            scale: _pulse,
              child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/lottie/poor.json',
                fit: BoxFit.contain,
                repeat: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Keep trying', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 6),
          const Text('Don\'t worry — practice makes perfect.'),
        ],
      );
    }
  }

  void _playAgainSameSettings() async {
    setState(() => _loading = true);
    try {
      final qs = await _api.fetchQuestions(amount: widget.amount, categoryId: widget.category.id, difficulty: widget.difficulty);
      if (!mounted) return;
      if (qs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No questions found for this configuration')));
        setState(() => _loading = false);
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuizScreen(questions: qs, category: widget.category, amount: widget.amount, difficulty: widget.difficulty)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.total > 0 ? widget.score / widget.total : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Stack(
        children: [
          // confetti layer (plays only for high scores)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Category: ${widget.category.name}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Text('Score: ${widget.score} / ${widget.total}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                // performance tier widget
                _buildPerformanceWidget(pct),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _playAgainSameSettings,
                    child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Play Again (same settings)'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                    },
                    child: const Text('Categories'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
