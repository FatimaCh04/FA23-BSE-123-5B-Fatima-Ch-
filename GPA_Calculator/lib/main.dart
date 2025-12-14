import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Dashboard',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF6F6FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

/// Welcome Screen (shows every time)
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    // Auto progress animation
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.05;
        if (_progress >= 1) {
          _progress = 1;
          timer.cancel();

          // Navigate to home after loading
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeShell(
                onToggleTheme: () {
                  final state =
                  context.findAncestorStateOfType<_MyAppState>();
                  if (state != null) {
                    state.setState(
                          () => state._mode = state._mode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
                  }
                },
              ),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo/Icon
                const Icon(Icons.school, size: 110, color: Colors.deepPurple),
                const SizedBox(height: 30),

                // App title
                Text(
                  'CUI GPA CALCULATOR',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 15),

                // Subtitle message
                Text(
                  'Easily calculate your GPA & CGPA with accuracy.\n'
                      'Designed exclusively for COMSATS University Students.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),

                // Progress bar
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.deepPurple,
                  backgroundColor: Colors.deepPurple.shade100,
                ),
                const SizedBox(height: 14),

                Text(
                  'Loading... ${(100 * _progress).toInt()}%',
                  style: GoogleFonts.poppins(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// HomeShell with Bottom Navigation (keeps your original pages)
class HomeShell extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeShell({super.key, required this.onToggleTheme});

  @override
  State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool isDarkMode = false;

  // Toggle function passed to SettingsScreen
  void toggleTheme(bool value) {
    setState(() => isDarkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const DashboardScreen(),
      SettingsScreen(
        onThemeToggle: toggleTheme,
        isDarkMode: isDarkMode,
      ),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(primary: Colors.deepPurple),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // 🌗 switch mode

      home: Scaffold(
        body: _pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.black54,
          backgroundColor: isDarkMode
              ? Colors.deepPurple.shade900
              : Colors.deepPurple.shade50,
          showUnselectedLabels: true,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////
//// DASHBOARD
//////////////////////////////////////////

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isDark = false;

  Widget featureCard({
    required BuildContext c,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color lightColor,
    required VoidCallback onTap,
  }) {
    final Color cardColor = isDark ? Colors.grey[900]! : lightColor;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isDark
                  ? Colors.deepPurple.shade300
                  : Colors.deepPurple.shade700,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double pad = 18;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            child: AppBar(
              backgroundColor: Colors.deepPurple,
              elevation: 4,
              title: const Text(
                'Comsats GPA Calculator',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isDark = !isDark;
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: isDark
                        ? const Color(0xFF1E1E1E)  // 🩶 dark container background
                        : Colors.white,             // 🤍 light container background
                    child: Image.asset(
                      'assets/images/logo-preview.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      color: isDark
                          ? Colors.white            // 🩶 make logo white-tinted if you want
                          : null,                    // original color in light mode
                      colorBlendMode: isDark ? BlendMode.modulate : null,
                    ),
                  ),
                ),


                const SizedBox(height: 20),

                Text(
                  'All Calculators',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    featureCard(
                      c: context,
                      icon: Icons.analytics_outlined,
                      title: 'Subject GPA',
                      subtitle: 'Check your grade',
                      lightColor: const Color(0xFFFFF7EC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SubjectGPACalculator()),
                        );
                      },
                    ),
                    featureCard(
                      c: context,
                      icon: Icons.calculate,
                      title: 'GPA Calculator',
                      subtitle: 'Semester GPA',
                      lightColor: const Color(0xFFECF5FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GPAPlaceholder()),
                        );
                      },
                    ),
                    featureCard(
                      c: context,
                      icon: Icons.auto_graph,
                      title: 'CGPA Calculator',
                      subtitle: 'Cumulative GPA',
                      lightColor: const Color(0xFFF5EEFF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CGPACalculator()),
                        );
                      },
                    ),
                    featureCard(
                      c: context,
                      icon: Icons.trending_up,
                      title: 'GPA Probability',
                      subtitle: 'Plan target GPA',
                      lightColor: const Color(0xFFF4FFF3),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GPAProbScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
//////////////////////////////////////////
/// SETTINGS SCREEN
//////////////////////////////////////////

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeToggle;
  final bool? isDarkMode;

  const SettingsScreen({super.key, this.onThemeToggle, this.isDarkMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);

  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: AppBar(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            title: const Text('Settings'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HomeShell(onToggleTheme: () {})),
                  );
                }
              },
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [


          const SizedBox(height: 10),

          // 🌙 Theme
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading:
              const Icon(Icons.palette_outlined, color: Colors.deepPurple),
              title: const Text('Theme Settings'),
              subtitle: Text(widget.isDarkMode == true
                  ? 'Dark Mode Enabled'
                  : 'Light Mode Enabled'),
              trailing: Switch(
                value: widget.isDarkMode ?? false,
                activeColor: Colors.deepPurple,
                onChanged: (val) => widget.onThemeToggle?.call(val),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🔔 Notifications
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading:
              const Icon(Icons.notifications, color: Colors.deepPurple),
              title: const Text('Notifications'),
              subtitle: const Text('Enable or disable app notifications'),
              trailing: Switch(
                value: _notificationsEnabled,
                activeColor: Colors.deepPurple,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                  _saveSettings();
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 💬 Feedback
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.feedback_outlined,
                  color: Colors.deepPurple),
              title: const Text('Send Feedback'),
              subtitle: const Text('Help us improve your experience'),
              onTap: () => _showSnack('Feedback form coming soon 💌'),
            ),
          ),

          const SizedBox(height: 10),

          // 🔒 Privacy Policy
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined,
                  color: Colors.deepPurple),
              title: const Text('Privacy Policy'),
              subtitle: const Text('View our data usage and privacy terms'),
              onTap: () => _showSnack('Privacy Policy page coming soon 🔒'),
            ),
          ),

          const SizedBox(height: 10),

          // ❓ Help Center
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading:
              const Icon(Icons.help_outline, color: Colors.deepPurple),
              title: const Text('Help & Support'),
              subtitle:
              const Text('FAQs, tutorials, and support contact info'),
              onTap: () => _showSnack('Help Center coming soon 💡'),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

////////////////////////////////
/// Subject GPA
///////////////////////////////

class SubjectGPAEntry {
  String name;
  int creditHours;
  List<Map<String, double>> assignments;
  List<Map<String, double>> quizzes;
  Map<String, double> mid;
  Map<String, double> finalExam;

  bool hasLab;
  List<Map<String, double>> labAssignments;
  List<Map<String, double>> labQuizzes;
  Map<String, double> labMid;
  Map<String, double> labFinal;

  SubjectGPAEntry({
    required this.name,
    this.creditHours = 3,
    required this.assignments,
    required this.quizzes,
    Map<String, double>? mid,
    Map<String, double>? finalExam,
    this.hasLab = false,
    required this.labAssignments,
    required this.labQuizzes,
    Map<String, double>? labMid,
    Map<String, double>? labFinal,
  })  : mid = mid ?? {'obtained': 0, 'total': 25},
        finalExam = finalExam ?? {'obtained': 0, 'total': 50},
        labMid = labMid ?? {'obtained': 0, 'total': 10},
        labFinal = labFinal ?? {'obtained': 0, 'total': 20};
}

class SubjectGPACalculator extends StatefulWidget {
  const SubjectGPACalculator({super.key});

  @override
  State<SubjectGPACalculator> createState() => _SubjectGPACalculatorState();
}

class _SubjectGPACalculatorState extends State<SubjectGPACalculator> {
  final List<SubjectGPAEntry> subjects = [];

  @override
  void initState() {
    super.initState();
    subjects.add(
      SubjectGPAEntry(
        name: '',
        assignments: [],
        quizzes: [],
        hasLab: false,
        labAssignments: [],
        labQuizzes: [],
      ),
    );
  }

  double marksToGradePoints(double marks) {
    if (marks >= 85) return 4.0;
    if (marks >= 80) return 3.67;
    if (marks >= 75) return 3.33;
    if (marks >= 70) return 3.0;
    if (marks >= 65) return 2.67;
    if (marks >= 60) return 2.33;
    if (marks >= 55) return 2.0;
    if (marks >= 50) return 1.67;
    if (marks >= 45) return 1.33;
    return 0.0;
  }

  double calculateTheoryPercentage(SubjectGPAEntry s) {
    double assignObt = s.assignments.fold(0, (sum, e) => sum + (e['obtained'] ?? 0));
    double assignTotal = s.assignments.fold(0, (sum, e) => sum + (e['total'] ?? 0));
    double quizObt = s.quizzes.fold(0, (sum, e) => sum + (e['obtained'] ?? 0));
    double quizTotal = s.quizzes.fold(0, (sum, e) => sum + (e['total'] ?? 0));
    double assignPercent = assignTotal == 0 ? 0 : assignObt / assignTotal;
    double quizPercent = quizTotal == 0 ? 0 : quizObt / quizTotal;
    double midPercent = s.mid['total']! == 0 ? 0 : s.mid['obtained']! / s.mid['total']!;
    double finalPercent = s.finalExam['total']! == 0 ? 0 : s.finalExam['obtained']! / s.finalExam['total']!;
    return ((assignPercent * 20) + (quizPercent * 10) + (midPercent * 25) + (finalPercent * 45));
  }

  double calculateLabPercentage(SubjectGPAEntry s) {
    if (!s.hasLab) return 0;
    double labAssignObt = s.labAssignments.fold(0, (sum, e) => sum + (e['obtained'] ?? 0));
    double labAssignTotal = s.labAssignments.fold(0, (sum, e) => sum + (e['total'] ?? 0));
    double labQuizObt = s.labQuizzes.fold(0, (sum, e) => sum + (e['obtained'] ?? 0));
    double labQuizTotal = s.labQuizzes.fold(0, (sum, e) => sum + (e['total'] ?? 0));
    double labMidPercent = s.labMid['total']! == 0 ? 0 : s.labMid['obtained']! / s.labMid['total']!;
    double labFinalPercent = s.labFinal['total']! == 0 ? 0 : s.labFinal['obtained']! / s.labFinal['total']!;
    return ((labAssignObt + labQuizObt + s.labMid['obtained']! + s.labFinal['obtained']!) /
        (labAssignTotal + labQuizTotal + s.labMid['total']! + s.labFinal['total']!)) *
        100;
  }

  double calculateGPA(SubjectGPAEntry s) {
    double theoryPercent = calculateTheoryPercentage(s);
    double theoryGPA = marksToGradePoints(theoryPercent);
    if (!s.hasLab) return theoryGPA;
    double labPercent = calculateLabPercentage(s);
    double labGPA = marksToGradePoints(labPercent);
    int totalCredits = s.creditHours;
    int labCredits = 1;
    int theoryCredits = totalCredits - labCredits;
    return ((theoryGPA * theoryCredits) + (labGPA * labCredits)) / totalCredits;
  }

  void addSubject() {
    setState(() {
      subjects.add(
        SubjectGPAEntry(
          name: '',
          assignments: [],
          quizzes: [],
          labAssignments: [],
          labQuizzes: [],
        ),
      );
    });
  }

  Widget buildMarksField(String label, Map<String, double> map) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: '$label Obtained',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => map['obtained'] = double.tryParse(v) ?? 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: '$label Total',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => map['total'] = double.tryParse(v) ?? 0,
          ),
        ),
      ],
    );
  }

  Widget buildEntryList(String title, List<Map<String, double>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        for (int i = 0; i < list.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Obtained',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => list[i]['obtained'] = double.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => list[i]['total'] = double.tryParse(v) ?? 0,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => list.removeAt(i)),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        ElevatedButton.icon(
          onPressed: () => setState(() => list.add({'obtained': 0, 'total': 0})),
          icon: const Icon(Icons.add),
          label: Text('Add ${title.split(' ').last}'),
        ),
      ],
    );
  }

  Widget buildSubjectCard(int index) {
    final s = subjects[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: s.name,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => s.name = v,
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: s.creditHours.toString(),
              decoration: const InputDecoration(
                labelText: 'Credit Hours',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => s.creditHours = int.tryParse(v) ?? 3,
            ),
            const SizedBox(height: 12),
            buildEntryList('Assignments', s.assignments),
            const SizedBox(height: 12),
            buildEntryList('Quizzes', s.quizzes),
            const SizedBox(height: 12),
            buildMarksField('Mid', s.mid),
            const SizedBox(height: 12),
            buildMarksField('Final', s.finalExam),
            const SizedBox(height: 16),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: s.hasLab,
                        onChanged: (val) => setState(() => s.hasLab = val ?? false),
                      ),
                      const Text(
                        'Has Lab?',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                  if (s.hasLab) ...[
                    const Divider(),
                    const Text('Lab Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    buildEntryList('Lab Assignments', s.labAssignments),
                    const SizedBox(height: 10),
                    buildEntryList('Lab Quizzes', s.labQuizzes),
                    const SizedBox(height: 10),
                    buildMarksField('Lab Mid', s.labMid),
                    const SizedBox(height: 10),
                    buildMarksField('Lab Final', s.labFinal),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  double gpa = calculateGPA(s);
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('GPA Result'),
                        content: Text(
                          'Subject GPA: ${gpa.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('OK', style: TextStyle(color: Colors.deepPurple)),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Calculate Subject GPA'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject GPA Calculator'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            for (int i = 0; i < subjects.length; i++) buildSubjectCard(i),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: addSubject,
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//////////////////////////////////////////
/// GPA Analyzer
//////////////////////////////////////////
class GPAPlaceholder extends StatefulWidget {
  const GPAPlaceholder({super.key});

  @override
  State<GPAPlaceholder> createState() => _GPAPlaceholderState();
}

class _GPAPlaceholderState extends State<GPAPlaceholder> {
  final List<TextEditingController> courseNameControllers = [];
  final List<TextEditingController> marksControllers = [];
  final List<TextEditingController> creditControllers = [];
  int courseCount = 1;

  double? gpa;

  // CUI Grading Scale
  double marksToGradePoints(double marks) {
    if (marks >= 85) return 4.0;
    if (marks >= 80) return 3.67;
    if (marks >= 75) return 3.33;
    if (marks >= 70) return 3.0;
    if (marks >= 65) return 2.67;
    if (marks >= 60) return 2.33;
    if (marks >= 55) return 2.0;
    if (marks >= 50) return 1.67;
    if (marks >= 45) return 1.33;
    return 0.0;
  }

  void calculateGPA() {
    double totalPoints = 0;
    double totalCredits = 0;

    for (int i = 0; i < courseCount; i++) {
      double? marks = double.tryParse(marksControllers[i].text);
      double? credits = double.tryParse(creditControllers[i].text);

      if (marks == null || credits == null) {
        // Show alert if invalid input
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Invalid Input'),
            content: Text(
              'Please enter valid numeric values for Marks and Credit Hours in Course ${i + 1}.',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK', style: TextStyle(color: Colors.deepPurple)),
              ),
            ],
          ),
        );
        return; // stop calculation
      }

      double gradePoints = marksToGradePoints(marks);
      totalPoints += gradePoints * credits;
      totalCredits += credits;
    }

    if (totalCredits == 0) return;

    setState(() {
      gpa = totalPoints / totalCredits;
    });

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('GPA Result'),
        content: Text(
          'Your Semester GPA is: ${gpa!.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize first course controllers
    courseNameControllers.add(TextEditingController());
    marksControllers.add(TextEditingController());
    creditControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    for (var c in courseNameControllers) c.dispose();
    for (var c in marksControllers) c.dispose();
    for (var c in creditControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Calculator (CUI)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // goes back to previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Enter your course names, marks, and credit hours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Dynamic editable course fields
            for (int i = 0; i < courseCount; i++)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: courseNameControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Course ${i + 1} Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: marksControllers[i],
                        decoration: const InputDecoration(
                          labelText: 'Marks (%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: creditControllers[i],
                        decoration: const InputDecoration(
                          labelText: 'Credit Hours',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      courseCount++;
                      courseNameControllers.add(TextEditingController());
                      marksControllers.add(TextEditingController());
                      creditControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: calculateGPA,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculate GPA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            if (gpa != null)
              Center(
                child: Text(
                  'GPA: ${gpa!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


//////////////////////////////////////////
/// CGPA SCREEN
//////////////////////////////////////////

class CGPACalculator extends StatefulWidget {
  const CGPACalculator({super.key});

  @override
  State<CGPACalculator> createState() => _CGPACalculatorState();
}

class _CGPACalculatorState extends State<CGPACalculator> {
  final List<TextEditingController> gpaControllers = [];
  final List<TextEditingController> creditControllers = [];
  int semesterCount = 1;
  double? cgpa;

  void calculateCGPA() {
    double totalWeightedPoints = 0;
    double totalCredits = 0;

    for (int i = 0; i < semesterCount; i++) {
      // Round each semester GPA to 2 decimals first (CUI-style)
      double gpa = double.tryParse(gpaControllers[i].text) ?? 0;
      gpa = double.parse(gpa.toStringAsFixed(2));

      double credits = double.tryParse(creditControllers[i].text) ?? 0;

      totalWeightedPoints += gpa * credits;
      totalCredits += credits;
    }

    if (totalCredits == 0) return;

    setState(() {
      cgpa = double.parse((totalWeightedPoints / totalCredits).toStringAsFixed(2));
    });

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CGPA Result'),
        content: Text(
          'Your CGPA is: $cgpa',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    gpaControllers.add(TextEditingController());
    creditControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    for (var c in gpaControllers) c.dispose();
    for (var c in creditControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator (CUI)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Enter your semester GPA and credit hours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Dynamic semester input
            for (int i = 0; i < semesterCount; i++)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Semester ${i + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: gpaControllers[i],
                          decoration: const InputDecoration(
                            labelText: 'GPA (e.g., 3.12)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: creditControllers[i],
                          decoration: const InputDecoration(
                            labelText: 'Credit Hours',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ]),
                ),
              ),

            const SizedBox(height: 12),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      semesterCount++;
                      gpaControllers.add(TextEditingController());
                      creditControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Semester'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: calculateCGPA,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculate CGPA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            if (cgpa != null)
              Center(
                child: Text(
                  'CGPA: $cgpa',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
///////////////////////////////////////
///      Prob    ////////
//////////////////////////////////////

class GPAProbScreen extends StatefulWidget {
  const GPAProbScreen({super.key});

  @override
  State<GPAProbScreen> createState() => _GPAProbScreenState();
}

class _GPAProbScreenState extends State<GPAProbScreen> {
  final TextEditingController currentCgpaController = TextEditingController();
  final TextEditingController semesterGpaController = TextEditingController();

  void calculateGpaPrediction() {
    final double? currentCgpa = double.tryParse(currentCgpaController.text);
    final double? semGpa = double.tryParse(semesterGpaController.text);

    if (currentCgpa == null || semGpa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values')),
      );
      return;
    }

    // Simple prediction: new CGPA = (old + new)/2 (you can modify later)
    final double newCgpa = ((currentCgpa + semGpa) / 2);

    String status;
    if (newCgpa < 2.00) {
      status = '⚠️ Probation (PRB)\nYour CGPA is below 2.00.';
    } else {
      status = '✅ Good Standing\nYou are safe from probation.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎓 GPA Prediction Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Predicted New CGPA: ${newCgpa.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(status),
            const SizedBox(height: 8),
            const Divider(),
            const Text(
              'Note: If your CGPA remains below 2.00 for two consecutive semesters, '
                  'you will be dismissed (DIS) as per COMSATS policy.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ✅ This closes the dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Probability'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GPA Probability Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your current CGPA and expected semester GPA to predict your new CGPA and see if you are at risk of probation.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: currentCgpaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Previous Semester CGPA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: semesterGpaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Semester CGPA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: calculateGpaPrediction,
                  icon: const Icon(Icons.auto_graph, color: Colors.white),
                  label: const Text(
                    'Check GPA Prediction',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}