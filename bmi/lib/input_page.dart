import 'package:bmi/constantFile.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'IconTextFile.dart';
import 'ContinerFile.dart';
import 'constantFile.dart';
import 'resultFile.dart';
import 'calculatorFile.dart';
enum Gender {
  male,
  female,
}

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  Gender? selectedGender; // Null safety fix
  int sliderHeight=180;
  int sliderWeight=60;
  int sliderAge=20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BMI Calculator"),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          /// -------- ROW 1 (Male / Female) --------
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RepeatContainer(
                    onPressed: () {
                      setState(() {
                        selectedGender = Gender.male;
                      });
                    },
                    colors: selectedGender == Gender.male
                        ? activeColor
                        : deActiveColor,
                    cardWidget: const IconText(
                      icon: FontAwesomeIcons.mars,
                      label: 'Male',
                    ),
                  ),
                ),
                Expanded(
                  child: RepeatContainer(
                    onPressed: () {
                      setState(() {
                        selectedGender = Gender.female;
                      });
                    },
                    colors: selectedGender == Gender.female
                        ? activeColor
                        : deActiveColor,
                    cardWidget: const IconText(
                      icon: FontAwesomeIcons.venus,
                      label: 'Female',
                    ),
                  ),
                ),
              ],
            ),
          ),
          /// -------- CENTER BOX --------
          Expanded(
            child: RepeatContainer(
                colors: deActiveColor,
                cardWidget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "HEIGHT",style: kLabelStyle,
                    ),
                    Row(
                      mainAxisAlignment:MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          sliderHeight.toString(),
                          style:kNumberStyle,
                        ),
                        Text(
                          'cm',
                          style: kLabelStyle,
                        ),
                      ],
                    ), Slider(
                      value: sliderHeight.toDouble(),
                      min: 12.0,
                      max: 220.0,
                      activeColor: Color(0xFFEB1555),
                      inactiveColor: Color(0xFF8D8E98),
                      onChanged: (double newValue){
                        setState(() {
                          sliderHeight=newValue.round();
                        });
                      },
                    ),
                  ],
                )
            ),
          ),
          /// -------- BOTTOM ROW --------
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RepeatContainer(
                      colors: deActiveColor,
                      cardWidget:Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "WEIGHT",style: kLabelStyle,
                          ),
                          Text(
                            sliderWeight.toString(),
                            style:kNumberStyle,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              RoundIcon(
                                iconData: FontAwesomeIcons.minus,
                                onPress: (){
                                  setState(() {
                                    sliderWeight--;
                                  });
                                },
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              RoundIcon(
                                iconData: FontAwesomeIcons.plus,
                                onPress: (){
                                  setState(() {
                                    sliderWeight++;
                                  });
                                },
                              ),

                            ],
                          ),
                        ],
                      )
                  ),
                ),
                Expanded(
                  child: RepeatContainer(
                      colors: deActiveColor,
                      cardWidget:Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Age",style: kLabelStyle,
                          ),
                          Text(
                            sliderAge.toString(),
                            style:kNumberStyle,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              RoundIcon(
                                iconData: FontAwesomeIcons.minus,
                                onPress: (){
                                  setState(() {
                                    sliderAge--;
                                  });
                                },
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              RoundIcon(
                                iconData: FontAwesomeIcons.plus,
                                onPress: (){
                                  setState(() {
                                    sliderAge++;
                                  });
                                },
                              ),

                            ],
                          ),
                        ],
                      )
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              CalculatorBrain calc=CalculatorBrain(height: sliderHeight,weight: sliderWeight);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ResultScreen(
                  bmiResult: calc.calculateBMI(),
                  resultText: calc.getResult(),
                  interpretation: calc.getInterpretation(),
                )),
              );
            },
            child: Container(
              color: const Color(0xFFEB1555),
              margin: const EdgeInsets.only(top: 10.0),
              width: double.infinity,
              height: 65.0,
              child: const Center(
                child: Text(
                  'Calculate',
                  style: kLargeButtonStyle,
                ),
              ),
            ),
          )

        ],
      ),
    );
  }
}

class RoundIcon extends StatelessWidget {
  final IconData iconData;
  final VoidCallback onPress;  // FIX → use VoidCallback

  const RoundIcon({
    Key? key,
    required this.iconData,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: onPress,
      elevation: 6.0,
      constraints: const BoxConstraints.tightFor(
        height: 45.0,
        width: 45.0,
      ),
      shape: const CircleBorder(),
      fillColor: const Color(0xFF4C4F5E),
      child: Icon(iconData),   // child after properties
    );
  }
}