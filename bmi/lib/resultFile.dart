import 'package:flutter/material.dart';
import 'constantFile.dart';
import 'ContinerFile.dart';
import 'input_page.dart';

class ResultScreen extends StatelessWidget{
  final String bmiResult;
  final String resultText;
  final String interpretation;

  ResultScreen({
    required this.bmiResult,
    required this.interpretation,
    required this.resultText
});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMI Result"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
              child: Container(
                child: Center(
                  child: Text(
                    'Your Result',
                    style: kTitleStyleS2,
                  ),
                ),
              )
          ),
          Expanded(
              flex: 5,
            child: RepeatContainer(
                colors: activeColor
            ,
            cardWidget:Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children:<Widget> [
                Text(
                  resultText.toUpperCase(),
                  style: kResultText,
                ),
                Text(
                  bmiResult,
                  style: kBMiTextStyle,
                ),
                Text(
                  interpretation,
                  textAlign: TextAlign.center,
                  style: kbodyTextStyle,
                )
              ],
            )

          ),
          ),
          Expanded(
              child:
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InputPage()),
              );
            },
            child: Container(
              color: const Color(0xFFEB1555),
              margin: const EdgeInsets.only(top: 10.0),
              width: double.infinity,
              height: 80.0,
              child: const Center(
                child: Text(
                  'ReCalculate',
                  style: kLargeButtonStyle,
                ),
              ),
            ),
          )
          ),
        ],
      ),
    );
  }
}