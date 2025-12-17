import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const LudoApp());

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo — Fun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', useMaterial3: true),
      home: const LudoScreen(),
    );
  }
}

class LudoScreen extends StatefulWidget {
  const LudoScreen({super.key});

  @override
  State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _playerCtrl = TextEditingController();
  final TextEditingController _turnCtrl = TextEditingController();

  List<String> players = [];
  List<int> scores = [];
  List<int> turnsLeft = [];
  int totalTurns = 0;
  int currentPlayer = 0;
  int dice = 1;
  bool gameStarted = false;

  late AnimationController _controller;
  late Animation<double> _diceRotation;

  final Color bg1 = const Color(0xFF7F7FD5);
  final Color bg2 = const Color(0xFF86A8E7);
  final Color bg3 = const Color(0xFF91EAE4);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _diceRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
    );
  }

  void addPlayer() {
    if (_playerCtrl.text.trim().isEmpty) return;
    setState(() {
      players.add(_playerCtrl.text.trim());
      scores.add(0);
      turnsLeft.add(totalTurns > 0 ? totalTurns : 0);
      _playerCtrl.clear();
    });
  }

  void startGame() {
    if (_turnCtrl.text.isEmpty || players.isEmpty) return;
    int? t = int.tryParse(_turnCtrl.text);
    if (t != null && t > 0) {
      setState(() {
        totalTurns = t;
        turnsLeft = List.filled(players.length, t);
        scores = List.filled(players.length, 0);
        currentPlayer = 0;
        gameStarted = false;
      });
    }
  }

  void rollDice() async {
    if (gameOver()) return;
    await _controller.forward(from: 0);

    final r = Random();
    setState(() {
      dice = r.nextInt(6) + 1;
      if (players.isNotEmpty && scores.length == players.length) {
        scores[currentPlayer] += dice;
      }
      gameStarted = true;

      if (dice != 6 && players.isNotEmpty) {
        turnsLeft[currentPlayer]--;
        do {
          currentPlayer = (currentPlayer + 1) % players.length;
        } while (turnsLeft[currentPlayer] == 0 && !gameOver());
      }
    });

    if (gameOver()) {
      Future.delayed(const Duration(milliseconds: 600), showWinnerDialog);
    }
  }

  void showWinnerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🏆 Congratulations!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        content: Text(
          'Winner: ${getWinnerName()} 🎉',
          style: const TextStyle(fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("Play Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              resetScores();
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text("Close"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void resetScores() {
    if (players.isEmpty) return;
    setState(() {
      scores = List.filled(players.length, 0);
      turnsLeft = List.filled(players.length, totalTurns);
      currentPlayer = 0;
      gameStarted = false;
      dice = 1;
    });
  }

  void resetGame() {
    setState(() {
      players.clear();
      scores.clear();
      turnsLeft.clear();
      totalTurns = 0;
      currentPlayer = 0;
      dice = 1;
      gameStarted = false;
      _playerCtrl.clear();
      _turnCtrl.clear();
    });
    _controller.stop();
    _controller.reset();
    FocusScope.of(context).unfocus();
  }

  bool gameOver() => turnsLeft.isNotEmpty && turnsLeft.every((t) => t == 0);

  String getWinnerName() {
    if (scores.isEmpty) return '';
    int maxScore = scores.reduce(max);
    return [
      for (int i = 0; i < players.length; i++)
        if (scores[i] == maxScore) players[i]
    ].join(', ');
  }

  Widget plainGlass({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.25),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2, bg3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '🎲 Ludo Fun!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 10, color: Colors.black45)
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Player + Turn Inputs
                plainGlass(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _playerCtrl,
                                decoration: const InputDecoration(
                                  hintText: "Enter player name",
                                  filled: true,
                                  fillColor: Colors.white70,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: addPlayer,
                              icon: const Icon(Icons.person_add),
                              label: const Text("Add"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigoAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _turnCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: "Turns per player",
                                  filled: true,
                                  fillColor: Colors.white70,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: startGame,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("Start"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Turn Info / Winner
                Text(
                  gameOver() && gameStarted
                      ? "🏆 Winner: ${getWinnerName()}!"
                      : players.isEmpty
                      ? "Add players to begin"
                      : "🎯 ${players[currentPlayer]}'s Turn",
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Dice
                GestureDetector(
                  onTap: players.isEmpty || gameOver() ? null : rollDice,
                  child: AnimatedBuilder(
                    animation: _diceRotation,
                    builder: (context, child) =>
                        Transform.rotate(angle: _diceRotation.value, child: child),
                    child: Image.asset('assets/images/dice$dice.png',
                        width: 150, height: 150),
                  ),
                ),
                const SizedBox(height: 25),

                // Roll Dice Button
                ElevatedButton.icon(
                  onPressed: players.isEmpty || gameOver() ? null : rollDice,
                  icon: const Icon(Icons.casino),
                  label: const Text("Roll Dice"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 6,
                  ),
                ),
                const SizedBox(height: 30),

                // Scoreboard
                if (players.isNotEmpty)
                  plainGlass(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('🏁 Scoreboard',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          for (int i = 0; i < players.length; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: [
                                  Colors.red,
                                  Colors.green,
                                  Colors.amber,
                                  Colors.blue
                                ][i % 4]
                                    .withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(players[i],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      "Score: ${scores[i]}  |  Turns: ${turnsLeft[i]}",
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),


                if (players.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: players.isEmpty ? null : resetScores,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Score'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        onPressed: resetGame,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
