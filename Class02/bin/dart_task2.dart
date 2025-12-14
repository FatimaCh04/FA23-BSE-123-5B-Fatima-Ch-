import 'dart:io';
import 'dart:convert';

// ===== Student Class =====
class Student {
  String name;
  int age;
  String city;
  List<String> hobbies;
  Set<String> subjects;

  Student(this.name, this.age, this.city,
      {this.hobbies = const [], this.subjects = const {}});

  // Convert Student to Map (for JSON)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'city': city,
      'hobbies': hobbies,
      'subjects': subjects.toList()
    };
  }

  // Display info
  void display() {
    print("Name: $name, Age: $age, City: $city");
    print("Hobbies: $hobbies");
    print("Subjects: $subjects");
  }
}

void main() {
  List<Student> students = [];
  bool running = true;

  while (running) {
    print("\n===== Student Menu =====");
    print("1. Add Student");
    print("2. Show Data");
    print("3. Export Data (JSON)");
    print("4. Filter by Hobby");
    print("5. Search by Name");
    print("6. Exit");
    stdout.write("Enter choice: ");
    String? choice = stdin.readLineSync();

    switch (choice) {
      case "1":
        addStudents(students);
        break;
      case "2":
        showData(students);
        break;
      case "3":
        exportData(students);
        break;
      case "4":
        filterHobbies(students);
        break;
      case "5":
        searchStudent(students);
        break;
      case "6":
        print("Goodbye!");
        running = false;
        break;
      default:
        print("Invalid choice, try again.");
    }
  }
}

// ===== Functions =====

// Add multiple students using do-while
void addStudents(List<Student> students) {
  String again;
  do {
    stdout.write("Enter name: ");
    String name = stdin.readLineSync() ?? "Unknown";

    int age = 0;
    try {
      stdout.write("Enter age: ");
      age = int.parse(stdin.readLineSync()!);
    } catch (e) {
      print("Invalid age, set to 0.");
    }

    stdout.write("Enter city: ");
    String city = stdin.readLineSync() ?? "Unknown";

    stdout.write("Enter hobbies (comma separated): ");
    List<String> hobbies =
    (stdin.readLineSync() ?? "").split(",").map((h) => h.trim()).toList();

    stdout.write("Enter subjects (comma separated): ");
    Set<String> subjects =
    (stdin.readLineSync() ?? "").split(",").map((s) => s.trim()).toSet();

    students.add(Student(name, age, city, hobbies: hobbies, subjects: subjects));
    print("✅ Student added!");

    stdout.write("Add another student? (y/n): ");
    again = stdin.readLineSync() ?? "n";
  } while (again.toLowerCase() == "y");
}

// Show all students
void showData(List<Student> students) {
  if (students.isEmpty) {
    print("No student data.");
  } else {
    print("\n===== Student Data =====");
    for (var s in students) {
      s.display();
      print("--------------------");
    }
  }
}

// Export students to JSON
void exportData(List<Student> students) {
  List<Map<String, dynamic>> data =
  students.map((s) => s.toMap()).toList();
  print("\nJSON Export:");
  print(jsonEncode(data));
}

// Filter students by hobby
void filterHobbies(List<Student> students) {
  stdout.write("Enter hobby to filter: ");
  String hobby = stdin.readLineSync() ?? "";
  var filtered = students.where((s) => s.hobbies.contains(hobby)).toList();

  if (filtered.isEmpty) {
    print("No student found with hobby '$hobby'.");
  } else {
    print("\nStudents with hobby '$hobby':");
    for (var s in filtered) {
      print(s.name);
    }
  }
}

// Search student by name
void searchStudent(List<Student> students) {
  stdout.write("Enter name to search: ");
  String name = stdin.readLineSync() ?? "";
  var found = students.where((s) => s.name.toLowerCase() == name.toLowerCase());

  if (found.isEmpty) {
    print("No student found with name '$name'.");
  } else {
    print("\nSearch Result:");
    for (var s in found) {
      s.display();
    }
  }
}
