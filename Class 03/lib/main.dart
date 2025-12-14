import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _num1Controller = TextEditingController();
  final TextEditingController _num2Controller = TextEditingController();
  double result = 0;

  void _calculate(String operation) {
    double num1 = double.tryParse(_num1Controller.text) ?? 0;
    double num2 = double.tryParse(_num2Controller.text) ?? 0;

    setState(() {
      if (operation == '+') {
        result = num1 + num2;
      } else if (operation == '-') {
        result = num1 - num2;
      } else if (operation == '×') {
        result = num1 * num2;
      } else if (operation == '÷') {
        result = num2 != 0 ? num1 / num2 : 0;
      } else if (operation == 'square') {
        result = num1 * num1;
      } else if (operation == 'cube') {
        result = num1 * num1 * num1;
      }
    });
  }

  void _reset() {
    setState(() {
      _num1Controller.clear();
      _num2Controller.clear();
      result = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          "Counter + Calculator",
          style: TextStyle(color: Colors.white), // Title white
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),

          Container(
            margin: const EdgeInsets.only(top: 40),
            child: const Text(
              'The App Changed By Fatima Ch.:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 70),

          Container(
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.teal, width: 3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _num1Controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Num 1",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _num2Controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Num 2",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Result: $result",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              spacing: 60,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () => _calculate('+'),
                  tooltip: 'Add',
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () => _calculate('-'),
                  tooltip: 'Subtract',
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () => _calculate('×'),
                  tooltip: 'Multiply',
                  child: const Icon(Icons.clear, color: Colors.white),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () => _calculate('÷'),
                  tooltip: 'Divide',
                  child: const Text(
                    "÷",
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () => _calculate('square'),
                  tooltip: 'Square',
                  child: const Text(
                    "x²",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () => _calculate('cube'),
                  tooltip: 'Cube',
                  child: const Text(
                    "x³",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: _reset,
                  tooltip: 'Reset',
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
