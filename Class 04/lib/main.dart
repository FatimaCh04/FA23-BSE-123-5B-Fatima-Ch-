import 'package:flutter/material.dart';

void main() => runApp(ProfileApp());

class ProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ProfilePage(), debugShowCheckedModeBanner: false);
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String name = 'Fatima Choudhry';
  final String email = 'fatimachoudhry94@gmail.com';
  final String phone = '+923043133364';
  final String tagline =
      'Computer Science Student | Flutter,C++, Python, HTML & OOP Learner';

  int selectedTheme = 0;
  String profileImage = 'images/12345.jpeg';
  bool toggleImage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional CV'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: _getBackgroundDecoration(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Theme Selection Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGradientButton('Classic', [
                      Colors.blue,
                      Colors.purple,
                    ], 0),
                    _buildGradientButton('Modern', [
                      Colors.orange,
                      Colors.red,
                    ], 1),
                    _buildGradientButton('Creative', [
                      Colors.green,
                      Colors.teal,
                    ], 2),
                  ],
                ),
                SizedBox(height: 20),
                _buildProfileCard(),
                SizedBox(height: 20),
                _buildAboutCard(),
                SizedBox(height: 20),
                _buildSkillsCard(),
                SizedBox(height: 20),
                _buildExperienceCard(),
                SizedBox(height: 20),
                _buildContactCard(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------- PROFILE CARD (FloatingActionButton) -------------------
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage(profileImage),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // Corrected FloatingActionButton with proper size & color
          SizedBox(
            height: 40, // smaller height
            child: FloatingActionButton.extended(
              heroTag: "changePicBtn",
              // backgroundColor: Color(0xFFB19CD9),
              backgroundColor: Colors.purple,

              onPressed: () {
                setState(() {
                  toggleImage = !toggleImage;
                  profileImage = toggleImage
                      ? 'images/12345.jpeg'
                      : 'images/PM.jpeg';
                });
              },
              icon: Icon(Icons.photo, size: 18, color: Colors.white),
              label: Text(
                "Change Photo",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),

          SizedBox(height: 5),
          Text(
            name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 5),
          Text(
            tagline,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- ABOUT CARD -------------------
  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.lightBlue[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.indigo, size: 24),
                SizedBox(width: 10),
                Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Text(
            "I am a Computer Science student with a strong interest in programming and problem-solving. "
            "Currently learning and working with Flutter,C++, Python, HTML, and Object-Oriented Programming concepts. "
            "I enjoy building academic projects and continuously improving my skills to become a professional developer.",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- SKILLS CARD -------------------
  Widget _buildSkillsCard() {
    List<Map<String, dynamic>> skills = [
      {
        'name': 'Flutter App Development',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      {
        'name': 'HTML & Web Design',
        'icon': Icons.phone_android,
        'color': Colors.blue,
      },
      {'name': 'C++ Programming', 'icon': Icons.web, 'color': Colors.green},
      {'name': 'Python Programing', 'icon': Icons.code, 'color': Colors.orange},
      {
        'name': 'Database Management',
        'icon': Icons.code,
        'color': Colors.orange,
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.indigo, size: 24),
              SizedBox(width: 10),
              Text(
                'Core Skills',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: skills.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: skills[index]['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: skills[index]['color'].withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: skills[index]['color'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          skills[index]['icon'],
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 15),
                      Text(
                        skills[index]['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- EXPERIENCE CARD -------------------
  Widget _buildExperienceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work, color: Colors.indigo, size: 24),
              SizedBox(width: 10),
              Text(
                'Experience',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          _buildExperienceItem(
            "Clinical Management System",
            "OOP Project",
            "2023",
          ),
          _buildExperienceItem(
            "Event Management System",
            "Database Project",
            "2024",
          ),
          _buildExperienceItem(
            "Blockchain Voting System",
            "Python Project",
            "2024",
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(String title, String company, String period) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          Text(
            company,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            period,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- CONTACT CARD -------------------
  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_mail, color: Colors.indigo, size: 24),
              SizedBox(width: 10),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildContactItem(Icons.email, email, 'Email'),
              _buildContactItem(Icons.phone, phone, 'Phone'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, String label) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo, size: 24),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ------------------- THEME BUTTONS -------------------
  Widget _buildGradientButton(String text, List<Color> colors, int themeIndex) {
    return GestureDetector(
      onTap: () => setState(() => selectedTheme = themeIndex),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration() {
    switch (selectedTheme) {
      case 1:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.blue, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 2:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.pink, Colors.red],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      default:
        return BoxDecoration(color: Colors.grey[100]);
    }
  }
}
